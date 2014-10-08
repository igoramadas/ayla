# STRAVA API
# -----------------------------------------------------------------------------
# Module to connect and retrieve sports data from Strava.
# More info at http://strava.github.io/api.
class Strava extends (require "./baseapi.coffee")

    expresser = require "expresser"

    async = expresser.libs.async
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    querystring = require "querystring"
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
                    @getRecentActivities()

        @baseStart()

    # Stop collecting data from Strava.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Strava API.
    apiRequest: (urlpath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth.authenticated]
            callback "Module not running or OAuth client not ready. Please check Strava API settings."
            return

        # Get data from the security module and set request URL.
        reqUrl = settings.strava.api.url + urlpath
        reqUrl += "?" + querystring.stringify params if params?

        logger.debug "Strava.apiRequest", reqUrl

        # Make request using OAuth.
        @oauth.get reqUrl, (err, result) =>
            result = JSON.parse result if lodash.isString result
            callback err, result

    # GET ATHLETES
    # ------------------------------------------------------------------------

    # Gets the list of the user's favorite tracks from Strava.
    getProfile: (callback) =>
        hasCallback = lodash.isFunction callback

        @apiRequest "athlete", (err, result) =>
            if err?
                @logError "Strava.getProfile", err
            else
                @setData "profile", result

            callback err, result if hasCallback

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

        hasCallback = lodash.isFunction callback
        filter = {} if not filter?

        @apiRequest "athlete/activities", filter, (err, result, resp) =>
            if err?
                @logError "Strava.getActivities", filter, err
            else
                @setData "activities", result, filter

            callback err, result if hasCallback

    # Gets a list of recent activities.
    getRecentActivities: (callback) =>
        hasCallback = lodash.isFunction callback
        filter = {after: moment().subtract(settings.strava.recentDays, "d").unix()}

        @getActivities filter, (err, result) =>
            @setData "recentActivities", result if result?
            callback err, result if hasCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
Strava.getInstance = ->
    @instance = new Strava() if not @instance?
    return @instance

module.exports = exports = Strava.getInstance()
