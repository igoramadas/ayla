# SERVER: SECURITY
# -----------------------------------------------------------------------------
# Controls authentication with users and external APIs.
class Security

    expresser = require "expresser"
    settings = expresser.settings

    crypto = require "crypto"
    database = require "./database.coffee"
    lodash = require "lodash"
    moment = require "moment"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Passport is accessible from outside.
    passport: require "passport"

    # Cache with logged users to avoid hitting the database all the time.
    # The default expirty time is 1 minute.
    cachedUsers: null

    # The default guest user. Will be set on init.
    guestUser: null

    # INIT
    # -------------------------------------------------------------------------

    # Init all security related stuff. Set the passport strategy to
    # authenticate users using basic HTTP authentication.
    init: =>
        @cachedUsers = {}

        # Only add passowrd protection if enabled on settings.
        return if not @getPassportStrategy()?

        # User serializer will user the user ID only.
        @passport.serializeUser (user, callback) => callback null, user.id

        # User deserializer will get user details from the database.
        @passport.deserializeUser (user, callback) =>
            if user is "guest"
                @validateUser "guest", null, callback
            else
                @validateUser {id: user}, false, callback

        # Enable LDAP authentication?
        if settings.passport.ldap.enabled
            ldapStrategy = (require "passport-ldapauth").Strategy
            ldapOptions =
                server:
                    url: settings.passport.ldap.server
                    adminDn: settings.passport.ldap.adminDn
                    adminPassword: settings.passport.ldap.adminPassword
                    searchBase: settings.passport.ldap.searchBase
                    searchFilter: settings.passport.ldap.searchFilter
                    tlsOptions: settings.passport.ldap.tlsOptions

            # Use `ldapauth` strategy.
            strategy = new ldapStrategy ldapOptions, (profile, callback) => @validateUser profile, null, callback
            @passport.use strategy
            expresser.logger.debug "Security", "Passport: using LDAP authentication."

        # Enable basic HTTP authentication?
        else if settings.passport.basic.enabled
            httpStrategy = (require "passport-http").BasicStrategy

            # Use `basic` strategy.
            strategy = new httpStrategy (username, password, callback) => @validateUser username, password, callback
            @passport.use strategy
            expresser.logger.debug "Security", "Passport: using basic HTTP authentication."

        # Make sure we have the admin user created and set guest user.
        @ensureAdminUser()
        @guestUser = {id: "guest", displayName: settings.security.guestDisplayName, username: "guest", roles: ["guest"]}

    # Authenticate user by checking request and cookies. Will redirect to the login page if not authenticated,
    # or send access denied if hasn't necessary roles. The `roles` and `redirect` are optional.
    # Returns true if auth passes or false if it doesn't.
    authenticate: (req, res, roles, redirect, callback) =>
        if not callback?
            if redirect?
                callback = redirect
                redirect = null
            else if roles?
                callback = roles
                roles = null
        if lodash.isBoolean roles
            redirect = roles
            roles = null

        # Check if user is authenticated and has the specified roles.
        # If not, redirect to the 401 access denied page.
        if req.user?
            if @checkUserRoles req.user, roles
                return callback true
            else
                res.redirect("/401") if redirect
                return callback false

        # Check if user cookie is set. If so, validate it now and check roles.
        if req.signedCookies?.user?
            @validateUser req.signedCookies.user, null, (err, result) =>
                if result? and result isnt false
                    @login req, res, {user: result, cookie: true, redirect: false}

                    if @checkUserRoles result, roles
                        return callback true
                    else
                        res.redirect("/401") if redirect
                        return callback false

        # Not authenticated if req.user is still empty, return false.
        if not req.user?
            res.redirect("/login") if redirect
            return callback false

    # Helper to validate user login. If no user was specified and [settings](settings.html)
    # allow guest access, then log as guest.
    validateUser: (user, password, callback) =>
        expresser.logger.debug "Security", "validateUser", user

        currentStrategy = @getPassportStrategy()

        if not user? or user is "" or user is "guest" or user.id is "guest"
            if settings.security.guestEnabled
                return callback null, @guestUser
            else
                return callback null, false, {message: "Invalid user!"}

        # Check if user is the username string or the full user object.
        if lodash.isString user
            filter = {username: user}
        else if user.id? and user.id isnt ""
            fromCache = @cachedUsers[user.id]
            filter = {id: user.id}
        else
            filter = {username: (if user.username? and user.username isnt "" then user.username else user.uid)}

        # Add password hash to filter.
        if password? and password isnt false and password isnt ""
            filter.passwordHash = @getPasswordHash user, password

        # Check if user was previously cached. If not valid, delete from cache.
        if fromCache?.cacheExpiryDate?
            if fromCache.cacheExpiryDate.isAfter(moment())
                return callback null, fromCache
            delete @cachedUsers[user.id]

        # Get user from database.
        database.getUser filter, (err, result) =>
            if err?
                return callback err

            # Check if user was found. If using LDAP, create the user if nothing was found,
            # otherwise just return a "user not found" error.
            if not result? or result.length < 1
                if currentStrategy is "ldapauth"
                    return @ldapCreateUser user, callback
                else
                    return callback null, false, {message: "User and password combination not found."}

            result = result[0] if result.length > 0

            # Check if user should be a forced admin.
            @checkForcedAdmin result

            # Set expiry date for the user cache.
            result.cacheExpiryDate = moment().add "s", settings.security.userCacheExpires
            @cachedUsers[result.id] = result

            # Callback with user result.
            return callback null, result

    # Ensure that there's at least one admin user registered. The default
    # admin user will have username "admin", password "system".
    ensureAdminUser: =>
        database.getUser null, (err, result) =>
            if err?
                return expresser.logger.error "Security.ensureAdminUser", err

            # If no users were found, create the default admin user.
            if not result? or result.length < 1
                passwordHash = @getPasswordHash "admin", "system"
                user = {displayName: "Administrator", username: "admin", roles: ["admin"], passwordHash: passwordHash}
                database.setUser user
                expresser.logger.info "Security.ensureAdminUser", "Default admin user was created."

    # Create user from LDAP if it's not yet registered on the MongoDB database.
    # LDAP users will have their password randomized.
    ldapCreateUser: (profile, callback) =>
        expresser.logger.info "Security.ldapCreateUser", profile

        # Create static password and user object.
        passwordHash = @getPasswordHash profile.uid, settings.passport.ldap.userPasswordPrefix + profile.uid
        user = {displayName: profile.cn, username: profile.uid, roles: ["ldap"], passwordHash: passwordHash}

        # Add user from LDAP to the database.
        database.setUser user, (err, result) ->
            if err?
                expresser.logger.error "Security.ldapCreateUser", err
            callback err, result

    # Check if the specified user has the necessary roles. Admin users always have permissions.
    # Returns true or false.
    checkUserRoles: (user, roles) =>
        return true if not roles? or roles.length < 1
        return true if lodash.indexOf(user.roles, "admin") >= 0

        diff = lodash.difference roles, user.roles

        # If roles difference is zero it means user has all roles.
        if diff.length < 1
            return true
        else
            return false

    # Check if the specified user is on the forced admin list, and if so add the "admin" role.
    checkForcedAdmin: (user) =>
        forcedAdmins = settings.security.forcedAdmins

        if forcedAdmins?.length > 0 and lodash.indexOf(forcedAdmins, user.username) >= 0
            user.roles.push "admin"


    # HELPER METHODS
    # ----------------------------------------------------------------------

    # Generates a password hash based on the provided `username` and `password`,
    # along with the `Settings.User.passwordSecretKey`. This is mainly used
    # by the HTTP authentication module. If password is empty, return an empty string.
    getPasswordHash: (username, password) =>
        return "" if not password? or password is ""
        text = username + "|" + password + "|" + settings.security.userPasswordKey
        return crypto.createHash("sha256").update(text).digest "hex"

    # Returns the current passport strategy by checking the `settings.passport` properties.
    getPassportStrategy: =>
        if settings.passport.ldap.enabled
            return "ldapauth"
        else if settings.passport.basic.enabled
            return "basic"
        return null

    # Helper to login user, mainly user to login as guest. Normal login operations are
    # handled automatically by the passport module (using basic and ldap auth).
    # If the optional `cookie` option is true, it will save a cookie with auth details.
    login: (req, res, options) =>
        user = options?.user

        # User must be defined.
        if not user?
            expresser.logger.warn "Security.login", "Invalid user (null or undefined)."
            res.redirect "/login?invalid_user" if options.redirect
            return

        # Check if guest is allowed.
        if not settings.security.guestEnabled and user.username is "guest"
            expresser.logger.warn "Security.login", "Guest access is not allowed."
            res.redirect "/login?guest_not_allowed" if options.redirect
            return

        # Log the user in.
        req.login user, (err) ->
            if err?
                expresser.logger.error "Security.login", user, err
                res.redirect "/login?error" if options.redirect
                return

            # Save to cookie?
            if options.cookie
                maxAge = settings.security.authCookieMaxAge * 60 * 60 * 1000
                res.cookie "user", user.username, {maxAge: maxAge, signed: true}

            res.redirect "/" if options.redirect

    # Logout and remove the specified user from the cache.
    logout: (req, res) =>
        delete @cachedUsers[req.user.id] if req.user?
        res.clearCookie "user"

        req.logout()
        res.redirect "/login"


# Singleton implementation
# --------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()