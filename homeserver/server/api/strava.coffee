# STRAVA API
# NOT READY YET!!!
# -----------------------------------------------------------------------------
# Module to connect to Strava.
# More info at www.strava.com.
class Strava extends (require "./baseapi.coffee")

    expresser = require "expresser"

    async = expresser.libs.async
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the Strava module.
    init: =>
        @baseInit()

    # Start collecting data from Strava.
    start: =>
        @oauthInit (err, result) =>
            if err?
                @logError "Strava.start", err
            else
                @baseStart()

                if settings.modules.getDataOnStart and result.length > 0
                    @getProfile()

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
        reqUrl = settings.strava.api.url + path
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
                @setData "profile", result

            callback err, result if lodash.isFunction callback

    # GET ACTIVITIES
    # ------------------------------------------------------------------------

    # Gets a list of activities for the current athlete. The filter can have
    # the before and after as timestamps (seconds since unix epoch), and
    # page and per_page options.
    getActivities: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        # Properly parse the filter.
        filter = {} if not filter?

        @apiRequest "athlete/activities", filter, (err, result, resp) =>
            if err?
                @logError "Strava.getActivities", filter, err
            else
                @setData "activities", result, filter

            callback err, result if lodash.isFunction callback

    # Gets a list of recent activities.
    getRecentActivities: (callback) =>
        filter = {after: moment().subtract(settings.strava.recentDays, "d").unix()}

        @getActivities filter, (err, result) =>
            if err?
                @logError "Strava.getRecentActivities", err
            else
                @setData "recentActivities", result

        callback err, result if lodash.isFunction callback

# Singleton implementation.
# -----------------------------------------------------------------------------
Strava.getInstance = ->
    @instance = new Strava() if not @instance?
    return @instance

module.exports = exports = Strava.getInstance()
