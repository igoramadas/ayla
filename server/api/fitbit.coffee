# FITBIT
# -----------------------------------------------------------------------------
class Fitbit

    expresser = require "expresser"
    logger = expresser.logger

    oauthModule = require "oauth"
    querystring = require "querystring"
    security = require "../security.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Fitbit module.
    init: =>
        logger.debug "Fitbit.init"

    # AUTH
    # -------------------------------------------------------------------------

    # Authentication helper for Fitbit.
    auth: (req, res, callback) =>
        oauth = new oauthModule.OAuth(
            settings.fitbit.authUrl + "request_token",
            settings.fitbit.authUrl + "access_token",
            settings.fitbit.apiKey,
            settings.fitbit.apiSecret,
            "1.0",
            null,
            "HMAC-SHA1")

    subscribe: =>
        postUrl = "#{settings.fitbit.apiUrl}user/-/apiSubscriptions/#{user.id}-all.json"

        # Subscribe this application to updates from the user's data
        oauth.post postUrl, token, tokenSecret, null, null, (err, data, res) ->
            if err?
                logger.error "Security.authFitbit", postUrl, err
            callback err, user

    # SLEEP
    # -------------------------------------------------------------------------

    getSleepData: (since) =>

    # ACTIVITIES
    # -------------------------------------------------------------------------

    # Post an activity to Fitbit.
    postActivity: (activity) =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Fitbit.getInstance = ->
    @instance = new Fitbit() if not @instance?
    return @instance

module.exports = exports = Fitbit.getInstance()