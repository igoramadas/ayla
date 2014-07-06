# UBI API
# -----------------------------------------------------------------------------
# Module to collect data from Ubi sensors and send Ubi commands.
# More info at www.theubi.com.
class Ubi extends (require "./baseapi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Ubi module.
    init: =>
        @baseInit()

    # Start collecting data from The Ubi.
    start: =>
        @oauthInit (err, result) =>
            if err?
                @logError "Ubi.start", err
            else
                @baseStart()

                if settings.modules.getDataOnStart and result.length > 0
                    @getDevices()

    # Stop collecting data from The Ubi.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Authentication helper for The Ubi.
    auth: (req, res) =>
        security.processAuthToken "ubi", req, res

    # Make a request to the Ubi API.
    apiRequest: (path, action, params, callback) =>
        if lodash.isFunction action
            callback = action
            action = null
        else if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth, @oauth.client]
            callback "Module not running or OAuth client not ready. Please check Ubi API settings." if callback?
            return

        # Set request URL and parameters.
        reqUrl = settings.ubi.api.url + path
        reqUrl = reqUrl + "/#{action}" if action?
        reqUrl = reqUrl + "?" + querystring.stringify params if params?

        # Make request using OAuth.
        @makeRequest reqUrl, (err, result) =>
            console.warn err, result

            if result?
                result = JSON.parse(result) if not lodash.isObject result
                err = result if result?.status > 0

            callback err, result

    # GET DATA
    # ------------------------------------------------------------------------

    # Get registered Ubi devices.
    getDevices: (callback) =>
        @apiRequest "list", (err, result) =>
            if err?
                @logError "Ubi.getDevices", err
            else
                @setData "devices", result.data
                logger.info "Ubi.getDevices", result.data

            callback err, result if lodash.isFunction callback

    # Get sensor data for the specified Ubi.
    getSensorData: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        # Properly parse the filter.
        filter = {} if not filter?

        @apiRequest deviceId, "sense", (err, result, resp) =>
            if err?
                logger.error "Ubi.getSensorData", filter, err
            else
                @setData "sensors", result, filter
                logger.info "Ubi.getSensorData", filter, result

            callback err, result if lodash.isFunction callback


# Singleton implementation.
# -----------------------------------------------------------------------------
Ubi.getInstance = ->
    @instance = new Ubi() if not @instance?
    return @instance

module.exports = exports = Ubi.getInstance()
