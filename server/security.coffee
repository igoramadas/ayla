# SERVER: SECURITY
# -----------------------------------------------------------------------------
# Controls authentication with users and external APIs.
class Security

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    crypto = require "crypto"
    lodash = require "lodash"
    moment = require "moment"
    oauthModule = require "oauth"
    passportFitbit = require "passport-fitbit"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Passport is accessible from outside.
    passport: require "passport"

    # Holds a copy of users and tokens.
    cachedTokens: []

    # INIT
    # -------------------------------------------------------------------------

    # Init the Security module. Set session management methods and init
    # auth procedures for all API modules.
    init: =>
        @passport.serializeUser @serializeUser
        @passport.deserializeUser @deserializeUser

        @initFitbit()

    # Init Fitbit auth and security.
    initFitbit: =>
        options = {consumerKey: settings.fitbit.apiKey, consumerSecret: settings.fitbit.apiSecret}
        strategy = new passportFitbit.Strategy options
        @passport.use strategy, @authFitbit

    # AUTH METHODS
    # -------------------------------------------------------------------------

    # Auth handler for Fitbit.
    authFitbit: (token, tokenSecret, user, callback) =>
        user.encodedId = user.id
        user.accessToken = token
        user.accessSecret = tokenSecret
        @saveUserToDb user

        # Create OAuth client, used to subscribe for notifications from Fitbit.
        oauth = new oauthModule.OAuth(
            settings.fitbit.oauthUrl + "request_token",
            settings.fitbit.oauthUrl + "access_token",
            settings.fitbit.apiKey,
            settings.fitbit.apiSecret,
            "1.0",
            null,
            "HMAC-SHA1")

        # Set subscription URL.
        postUrl = "#{settings.fitbit.apiUrl}user/-/apiSubscriptions/#{user.id}-all.json"

        # Subscribe this application to updates from the user's data
        oauth.post postUrl, token, tokenSecret, null, null, (err, data, res) ->
            if err?
                logger.error "Security.authFitbit", postUrl, err
            callback err, user

    # SESSION MANAGEMENT
    # -------------------------------------------------------------------------

    # Helper to serialize authenticated users.
    serializeUser: (user, callback) =>
        logger.debug "Security.serializeUser", user
        callback null, user.id

    # Helper to deserialize users.
    deserializeUser: (user, callback) =>
        logger.debug "Security.deserializeUser", user
        @validateUser user, callback

    # Helper to validate user data.
    validateUser: (user, callback) =>
        callback null, user

    # DATABASE SYNC
    # -------------------------------------------------------------------------

    # Save user info or tokens to the database.
    saveUserToDb: (user, callback) =>
        database.set "auth", user, (err, result) =>
            if err?
                logger.error "Security.saveUserToDb", user.id, err
            if callback?
                callback err, result


# Singleton implementation
# -----------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()