# PHILIPS HUE API
# -----------------------------------------------------------------------------
# Module to identify and control Hue bridges and lamps.
# More info at http://developers.meethue.com
class Hue extends (require "./baseapi.coffee")

    expresser = require "expresser"

    async = expresser.libs.async
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    networkApi = require "./network.coffee"
    settings = expresser.settings
    url = require "url"
    utils = expresser.utils

    # INIT
    # -------------------------------------------------------------------------

    # Init the Hue module and schedule a job to refresh the hub status every few seconds.
    init: =>
        @baseInit()

    # Start the module and refresh the Hue hub data.
    start: =>
        @baseStart()

        events.on "hue.switchgrouplights", @switchGroupLights
        events.on "hue.setlightstate", @setLightState

        if settings.modules.getDataOnStart
            @refreshHub()

    # Stop the module and cancel the Hue hub refresh jobs.
    stop: =>
        @baseStop()

        events.off "hue.switchgrouplights", @switchGroupLights
        events.off "hue.setlightstate", @setLightState

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
                # Clean results, delete whitelist for security reasons and remove pointsymbol data.
                delete results.config.whitelist if results?.config?
                delete light.pointsymbol for key, light of results.lights

                # Save to DB.
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
            for i in arr
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
                events.emit "hue.light.state", filter, state

            callback err, results if callback?

    # Turn group lights on (true) or off (false). If no ID is passed or ID is 0, switch all lights.
    switchGroupLights: (id, turnOn, callback) =>
        logger.debug "Hue.switchGroupLights", turnOn

        if not turnOn?
            turnOn = id
        else if lodash.isFunction turnOn
            callback = turnOn

        if not id? or lodash.isBoolean id
            id = 0

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
