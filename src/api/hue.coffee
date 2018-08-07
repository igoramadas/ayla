# PHILIPS HUE API
# -----------------------------------------------------------------------------
# Module to identify and control Hue bridges, lamps and lights.
# More info at http://developers.meethue.com.
class Hue extends (require "./baseapi.coffee")

    expresser = require "expresser"
    async = expresser.libs.async
    datastore = expresser.datastore
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    appData = require "../appdata.coffee"
    url = require "url"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Hue module and schedule a job to refresh the hub status every few seconds.
    init: =>
        @baseInit()

        async = expresser.libs.async
        lodash = expresser.libs.lodash

    # Start the module and refresh the Hue hub data.
    start: =>
        @baseStart()

        events.on "Hue.switchGroupLights", @switchGroupLights
        events.on "Hue.setLightState", @setLightState

        @refreshHub()

    # Stop the module and cancel the Hue hub refresh jobs.
    stop: =>
        @baseStop()

        events.off "Hue.switchGroupLights", @switchGroupLights
        events.off "Hue.setLightState", @setLightState

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to get all lights IDs.
    getLightIds: =>
        result = []
        result.push i for i of @data.hub.lights
        return result

    # Make a request to the Hue API.
    apiRequest: (urlPath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        # Get Hue bridge info from settings.
        device = lodash.find appData.network.devices, {type: "hue"}

        # No device found? Abort!
        if not @isRunning [settings.hue?.api, device]
            errMsg = "Hue bridge was not found on network device list. Please check appData.network.devices."

            if lodash.isFunction callback
                callback errMsg
            else
                logger.warn "Hue.apiRequest", errMsg
            return

        reqUrl = "http://#{device.ip}:#{device.port}/api/#{settings.hue.api.user}/" + urlPath

        # Make request. The hue API sometimes is not super stable, so try once
        # more before triggering errors to the callback.
        @makeRequest reqUrl, params, (err, result) =>
            if not err?
                callback null, result
            else
                lodash.delay @makeRequest, 1000, reqUrl, params, callback

    # GET HUB DATA
    # -------------------------------------------------------------------------

    # Refresh information from the Hue hub.
    refreshHub: (callback) =>
        logger.debug "Hue.refreshHub"

        @apiRequest "", (err, results) =>
            if err?
                logger.error "Hue.refreshHub", err
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

            callback? err, results

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
                logger.error "Hue.setLightState", filter, state, err
            else
                logger.info "Hue.setLightState", filter, state
                events.emit "Hue.light.state", filter, state

            callback? err, results

    # Turn group lights on (true) or off (false). If no ID is passed or ID is 0, switch all lights.
    switchGroupLights: (id, turnOn, callback) =>
        logger.debug "Hue.switchGroupLights", turnOn

        if not turnOn? or lodash.isFunction turnOn
            callback = turnOn
            turnOn = id

        if not id? or lodash.isBoolean id
            id = 0

        @setLightState {groupId: id}, {on: turnOn}, callback

    # Turn the specified light on (true) or off (false).
    switchLight: (id, turnOn, callback) =>
        logger.debug "Hue.switchLight", id, turnOn

        @setLightState {lightId: id}, {on: turnOn}, callback

# Singleton implementation.
# -----------------------------------------------------------------------------
Hue.getInstance = ->
    @instance = new Hue() if not @instance?
    return @instance

module.exports = exports = Hue.getInstance()
