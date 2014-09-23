# GARMIN API
# -----------------------------------------------------------------------------
# Module to collect data from Garmin.
# More info at http://connect.garmin.com.
class Garmin extends (require "./baseapi.coffee")

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

    # Init the Garmin module.
    init: =>
        @baseInit()

    # Start collecting data from Garmin Connect.
    start: =>
        @baseStart()

        if settings.modules.getDataOnStart and @isRunning [settings.garmin.api.username]
            @getSleep()

    # Stop collecting data from Garmin Connect.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to signin and get the session token.
    login: =>
        reqUrl = "#{settings.garmin.api.loginUrl}"

        params = {method: "POST"}
        params.body = {
            "login": "login"
            "login:loginUsernameField": settings.garmin.api.username
            "login:password": settings.garmin.api.password
            "login:signInButton": "Sign In"}

        @makeRequest reqUrl, params, (err, result) =>
            callback err, result

    # Helper to make requests to the Garmin Connect website.
    apiRequest: (service, urlpath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = {}

        if not @isRunning [settings.garmin.api]
            callback "Garmin Connect API is not set, please check the settings."
            return

        reqUrl = "#{settings.garmin.api.url}#{service}/#{urlpath}"

        # Set queries based on params (query or stationId).
        # If `stationId` is set, add pws: to the URL.
        reqUrl += querystring.stringify params if params?

        @makeRequest reqUrl, (err, result) =>
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
            console.warn err, result

            if err?
                @logError "Garmin.getSleep", filter, err
            else
                @setData "sleep", result, filter

            callback err, result if hasCallback

    getRecentSleep: (callback) =>
        hasCallback = lodash.isFunction callback

        @getSleep {from: from, to: to}, (err, result) =>
            if not err?
                @setData "recentSleep", result


# Singleton implementation.
# -----------------------------------------------------------------------------
Garmin.getInstance = ->
    @instance = new Garmin() if not @instance?
    return @instance

module.exports = exports = Garmin.getInstance()
