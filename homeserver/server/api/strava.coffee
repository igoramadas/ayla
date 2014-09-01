# STRAVA API
# NOT READY YET!!!
# -----------------------------------------------------------------------------
# Module to connect to Strava.
# More info at www.strava.com.
class Strava extends (require "./baseapi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Strava module.
    init: =>
        @baseInit()

    # Start collecting data from Strava.
    start: =>
        @baseStart()

    # Stop collecting data from Strava.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Strava API.
    apiRequest: (path, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth, @oauth.client]
            callback "Module not running or OAuth client not ready. Please check Strava API settings." if callback?
            return

        # Get data from the security module and set request URL.
        reqUrl = settings.toshl.api.url + path
        reqUrl += "?" + querystring.stringify params if params?

        logger.debug "Strava.apiRequest", reqUrl

        # Make request using OAuth.
        @oauth.get reqUrl, (err, result) =>
            result = JSON.parse result if lodash.isString result
            callback err, result if lodash.isFunction callback

    # GET ATHLETES
    # ------------------------------------------------------------------------

    # Gets the list of the user's favorite tracks from Strava.
    getProfile: (callback) =>
        @apiRequest "athlete", (err, result) =>
            if err?
                @logError "Strava.getProfile", err
            else
                @setData "profile", result, filter

            callback err, result if lodash.isFunction callback

# Singleton implementation.
# -----------------------------------------------------------------------------
Strava.getInstance = ->
    @instance = new Strava() if not @instance?
    return @instance

module.exports = exports = Strava.getInstance()
