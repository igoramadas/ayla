# PHILIPS HUE API
# -----------------------------------------------------------------------------
# Module to identify and control Hue bridges and lamps.
# More info at http://developers.meethue.com
class Hue extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    networkApi = require "./network.coffee"
    url = require "url"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Hue module and schedule a job to refresh the hub status every few seconds.
    init: =>
        @baseInit()

    # Start the module and refresh the Hue hub data.
    start: =>
        @refreshHub()
        @baseStart()

    # Stop the module and cancel the Hue hub refresh jobs.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to get all lights IDs.
    getLightIds: =>
        result = []
        result.push i for i of @data.hub.lights
        return result

    # Make a request to the Hue API.
    apiRequest: (urlPath, params, callback) =>
        if not settings.hue?.api?
            logger.warn "Hue.apiRequest", "Hue API settings are not defined. Abort!"
            return

        # Set correct parameters.
        if lodash.isFunction params
            callback = params
            params = null

        # Get device info from settings.
        device = lodash.find settings.network.devices, {type: "hue"}
        
        # No device found? Abort!
        if not @isRunning [device]
            errMsg = "Hue bridge was not found on network device list. Please check settings.network.devices."
            if lodash.isFunction callback
                callback errMsg
            else
                logger.warn "Hue.apiRequest", errMsg
            return

        # Get correct URL depending on home or remote location.
        if networkApi.isHome
            baseUrl = "http://#{device.ip}:#{device.localPort}/api/#{settings.hue.api.user}/"
        else
            baseUrl = "http://#{settings.network.router.remoteHost}:#{device.remotePort}/api/#{settings.hue.api.user}/"

        reqUrl = baseUrl + urlPath

        # Make request. The hue API sometimes is not super stable, so try once
        # more before triggering errors to the callback.
        @makeRequest reqUrl, params, (err, result) =>
            if not err?
                callback err, result
            else
                lodash.delay @makeRequest, 1000, reqUrl, params, callback

    # GET HUB DATA
    # -------------------------------------------------------------------------

    # Refresh information from the Hue hub.
    refreshHub: (callback) =>
        logger.debug "Hue.refreshHub"

        @apiRequest "", (err, results) =>
            if err?
                @logError "Hue.refreshHub", err
            else
                @setData "hub", results

                # Get hub counters.
                lightCount = 0
                groupCount = 0
                lightCount = lodash.keys(results.lights).length if results?.lights?
                groupCount = lodash.keys(results.groups).length if results?.groups?

                # Log and emit refresh event.
                logger.info "Hue.refreshHub", "#{lightCount} lights and #{groupCount} groups."

            callback err, results if callback?

    # LIGHT CONTROL
    # -------------------------------------------------------------------------

    # Main function to set light state (switch, colour, brightness etc).
    setLightState: (filter, state, callback) =>
        if not filter?
            throw new Error "A valid light, array of lights or filter must be specified."
        else
            logger.debug "Hue.setLightState", filter, state

        # Set request parameter to use PUT and pass the full state and create tasks array.
        params = {method: "PUT", body: state}
        tasks = []

        # Check if id is a single light or an array of lights (if any).
        if filter.lightId?
            if lodash.isArray filter.lightId
                arr = filter.lightId
            else
                arr = [filter.lightId]

            # Make the light state change request for all specified ids.
            for i of arr
                do (i) => tasks.push (cb) => @apiRequest "lights/#{i}/state", params, cb

        # Check if id is a single group or an array of groups (if any).
        if filter.groupId?
            if lodash.isArray filter.groupId
                arr = filter.groupId
            else
                arr = [filter.groupId]

            # Make the light state change request for all specified ids.
            for i of arr
                do (i) => tasks.push (cb) => @apiRequest "groups/#{i}/action", params, cb

        # Execute requests in parallel.
        async.parallelLimit tasks, settings.general.parallelTasksLimit, (err, results) =>
            if err?
                @logError "Hue.setLightState", filter, state, err
            else
                logger.info "Hue.setLightState", filter, state
                events.emit "hue.lights.state", filter, state

            callback err, results if callback?

    # Turn all lights on (true) or off (false).
    switchAllLights: (turnOn, callback) =>
        logger.debug "Hue.switchAllLights", turnOn
        @setLightState {groupId: 0}, {on: turnOn}, callback

    # Turn group lights on (true) or off (false).
    switchGroupLights: (id, turnOn, callback) =>
        logger.debug "Hue.switchGroupLights", turnOn
        @setLightState {groupId: id}, {on: turnOn}, callback

    # Turn the specified light on (true) or off (false).
    switchLight: (id, turnOn, callback) =>
        logger.debug "Hue.switchLight", id, turnOn
        @setLightState {lightId: id}, {on: turnOn}, callback

    # JOBS
    # -------------------------------------------------------------------------

    # Scheduled job to refresh the hub data.
    jobRefreshHub: =>
        logger.info "Hue.jobRefreshHub"

        @refreshHub()


# Singleton implementation.
# -----------------------------------------------------------------------------
Hue.getInstance = ->
    @instance = new Hue() if not @instance?
    return @instance

module.exports = exports = Hue.getInstance()