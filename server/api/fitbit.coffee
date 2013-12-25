# FITBIT
# -----------------------------------------------------------------------------
class Fitbit

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

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


        security.processAuthToken "fitbit", {version: "1.0"}, req, res, (err, result) =>
            console.warn err, result

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