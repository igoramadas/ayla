# UBI API
# -----------------------------------------------------------------------------
# Module to collect data from Ubi sensors and send Ubi commands.
# More info at http://www.theubi.com.
class Ubi extends (require "./baseapi.coffee")

    expresser = require "expresser"

    async = expresser.libs.async
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    querystring = require "querystring"
    settings = expresser.settings

    # Ubi sensor type list.
    sensorTypes = ["temperature", "humidity", "airpressure", "light", "soundlevel"]

    # INIT
    # -------------------------------------------------------------------------

    # Init the Ubi module.
    init: =>
        @baseInit()

    # Start collecting data from the Ubi.
    start: =>
        @oauthInit (err, result) =>
            if err?
                @logError "Ubi.start", err
            else
                @baseStart()

                if settings.modules.getDataOnStart and result.length > 0
                    @getDevices (err, result) => @getSensorData() if not err?

    # Stop collecting data from the Ubi.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Ubi API.
    apiRequest: (path, action, params, callback) =>
        if lodash.isFunction action
            callback = action
            action = null
        else if lodash.isFunction params
            callback = params
            params = null

        # Make sure API settings were initialized.
        if not @isRunning [@oauth]
            callback "Module not running or OAuth client not ready. Please check Ubi API settings."
            return

        # Set request URL and parameters.
        params = {} if not params?
        params.access_token = @oauth.data.accessToken
        reqUrl = settings.ubi.api.url + path
        reqUrl = reqUrl + "/#{action}" if action?
        reqUrl = reqUrl + "?" + querystring.stringify params

        # Make request using OAuth.
        @makeRequest reqUrl, {parseJson: true}, (err, result) =>
            callback err, result

    # GET DATA
    # ------------------------------------------------------------------------

    # Get registered Ubi devices.
    getDevices: (callback) =>
        hasCallback = lodash.isFunction callback
        
        @apiRequest "list", (err, result) =>
            if err?
                @logError "Ubi.getDevices", err
            else
                @setData "devices", result.result.data
                logger.info "Ubi.getDevices", result.result.data

            callback err, result if hasCallback

    # Get sensor data for the specified Ubi.
    getSensorData: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback

        # If device ID was passed then use it, otherwise get for all devices.
        if filter?.id?
            deviceIds = [filter.id]
        else
            deviceIds = lodash.pluck @data.devices[0].value, "id"

        tasks = []

        # Get sensor data for all or specified device(s).
        for id in deviceIds
            do (id) =>

                # Each sensor must be fetched manually for now.
                for sType in sensorTypes
                    do (sType) =>
                        tasks.push (cb) =>
                            @apiRequest id, "sense", {sensor_type: sType}, (err, result) =>

                                # Add sensor type to result, if valid.
                                if result?
                                    result.device_id = id
                                    result.sensor_type = sType
                                cb err, result

        # Sensor data will be fetched in parallel.
        async.parallelLimit tasks, settings.general.parallelTasksLimit, (err, results) =>
            if err?
                @logError "Ubi.getSensorData", filter, err
            else
                deviceData = {device_id: results[0]?.device_id}
                filter = {device_id: results[0]?.device_id} if not filter?

                # Merge result data.
                for r in results
                    deviceData[r.sensor_type] = r.result.data

                # Save merged data.
                @setData "sensors", deviceData, filter

            callback err, deviceData if hasCallback

    # SET AND SEND DEVICE DATA
    # -------------------------------------------------------------------------

    # Passes a phrase to be spoken by the Ubi.
    speak: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback

        # The phrase is mandatory.
        if not filter.phrase? or filter.phrase is ""
            errorMsg = "The filter.phrase is missing or empty, phrase parameter is mandatory."
            logger.warn "Ubi.speak", filter, errorMsg
            callback errorMsg, null if hasCallback
            return

        # If device ID was passed then use it, otherwise get for all devices.
        if filter?.id?
            deviceIds = [filter.id]
        else
            deviceIds = lodash.pluck @data.devices, "id"

        # Get sensor data for all or specified device.
        for id in deviceIds
            (id) =>
                @apiRequest id, "speak", {phrase: filter.phrase}, (err, result) =>
                    if err?
                        @logError "Ubi.speak", filter, err
                    else
                        @setData "phrases", result, filter

                    callback err, result if hasCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
Ubi.getInstance = ->
    @instance = new Ubi() if not @instance?
    return @instance

module.exports = exports = Ubi.getInstance()
