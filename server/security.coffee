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

    # INIT
    # -------------------------------------------------------------------------

    # Init all security related stuff. Set the passport strategy to
    # authenticate users using basic HTTP authentication.
    init: =>
        @cachedUsers = {}

        # Only add passowrd protection if enabled on settings.
        return if not @getPassportStrategy()?


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


# Singleton implementation
# -----------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()