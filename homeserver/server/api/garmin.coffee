# GARMIN CONNECT API
# -----------------------------------------------------------------------------
# Module to get activities and general health data from Garmin Connect.
# Implemented using a headless browser (Zombie) to simulate a browser
# and get data, avoiding the $5000 fee charged for the Garmin API.
# More info at http://connect.garmin.com.
class Garmin extends (require "./baseapi.coffee")

    expresser = require "expresser"

    assert = require "assert"
    async = expresser.libs.async
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    querystring = require "querystring"
    settings = expresser.settings
    zombie = require "zombie"

    # Zombie browser state objects.
    zombieBrowser: null
    cookie: {data: null, timestamp: 0}

    # INIT
    # -------------------------------------------------------------------------

    # Init the Garmin module.
    init: =>
        @baseInit()

    # Start collecting data from Garmin Connect.
    start: =>
        @baseStart()

        if settings.modules.getDataOnStart and @isRunning [settings.garmin.api.username]
            @login (err, result) =>
                if not err?
                    @getRecentSleep()

    # Stop collecting data from Garmin Connect.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to login and get the session token.
    login: (callback) =>
        if not @zombieBrowser?
            zombie.debug() if settings.general.debug
            @zombieBrowser = zombie.create {maxRedirects: 10}
            @zombieBrowser.resources.mock "https://www.google-analytics.com/analytics.js", {}

        try
            @zombieBrowser.visit settings.garmin.api.loginUrl, (err) =>
                if err?
                    @logError "Garmin.login", "Could not fetch sigin page.", err
                    return callback err

                @zombieBrowser.fill "#username", settings.garmin.api.username
                @zombieBrowser.fill "#password", settings.garmin.api.password

                @zombieBrowser.pressButton "#login-btn-signin", (err) =>
                    @cookie.data = @zombieBrowser.cookies
                    @cookie.timestamp = moment().unix()

                    callback null
        catch ex
            @logError "Garmin.login", "Exception", ex.message, ex.stack
            callback {exception: ex}

    # Helper to make requests to the Garmin Connect website.
    apiRequest: (service, urlpath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = {}

        if not @isRunning [settings.garmin.api.username]
            callback "Garmin Connect API is not set, please check the settings."
            return

        reqUrl = "#{settings.garmin.api.url}#{service}/#{urlpath}"

        # Set queries based on params (query or stationId).
        # If `stationId` is set, add pws: to the URL.
        reqUrl += "?" + querystring.stringify params if params?

        # Set request options.
        options = {headers: {"Accept": "application/json"}}

        @zombieBrowser.resources.request "GET", reqUrl, options, (err, result) =>
            if result?.body?
                try
                    result = result.body.toString "utf8"
                    result = JSON.parse result
                catch ex
                    @logError "Garmin.apiRequest", "Could not parse response JSON.", ex.message, ex.stack
                    result = null

            callback err, result

    # GET SLEEP DATA
    # ------------------------------------------------------------------------

    # Gets the list of registered devices with Garmin.
    getSleep: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback

        @apiRequest "wellness-service", "wellness/dailySleeps", filter, (err, result) =>
            if err?
                @logError "Garmin.getSleep", filter, err
            else
                @setData "sleep", result, filter

            callback err, result if hasCallback

    # Get sleep data for recent days, default is 30.
    getRecentSleep: (callback) =>
        hasCallback = lodash.isFunction callback

        @getSleep {limit: settings.garmin.recentDays}, (err, result) =>
            @setData "recentSleep", result if result?
            callback err, result if hasCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
Garmin.getInstance = ->
    @instance = new Garmin() if not @instance?
    return @instance

module.exports = exports = Garmin.getInstance()
