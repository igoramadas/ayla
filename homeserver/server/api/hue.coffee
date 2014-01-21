# PHILIPS HUE API
# -----------------------------------------------------------------------------
class Hue extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    async = require "async"
    lodash = require "lodash"
    network = require "./network.coffee"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds the current URL in use for the API (local or remote).
    apiUrl: ""

    # INIT
    # -------------------------------------------------------------------------

    # Init the Hue module and schedule a job to refresh the hub status every few seconds.
    init: =>
        @baseInit()

    # Start the module and refresh the Hue hub data.
    start: =>
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
        if lodash.isFunction params
            callback = params
            params = null

        # Set full URL and make the HTTP request.
        baseUrl = (if network.isHome then settings.hue.api.localUrl else settings.hue.api.remoteUrl)
        reqUrl = baseUrl + settings.hue.api.user + "/" + urlPath
        @makeRequest reqUrl, params, callback

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
                events.emit "hue.hub.refresh"

            callback err, results if callback?

    # LIGHT CONTROL
    # -------------------------------------------------------------------------

    # Main function to set light state (switch, colour, brightness etc).
    setLightState: (id, state, callback) =>
        if not id?
            throw new Error "A valid light (or array of) id must be specified."
        else
            logger.debug "Hue.setLightState", id, state

        # Set request parameter to use PUT and pass the full state and create tasks array.
        params = {method: "PUT", body: state}
        tasks = []

        # Check if id is a single light or an array of lights.
        if lodash.isArray id
            arr = id
        else
            arr = [id]

        # Make the light state change request for all specified ids.
        for i of arr
            do (i) => tasks.push (cb) => @apiRequest "lights/#{i}/state", params, cb

        # Execute requests in parallel.
        async.parallelLimit tasks, settings.general.parallelTasksLimit, (err, results) =>
            if err?
                @logError "Hue.setLightState", id, state, err
            else
                logger.info "Hue.setLightState", id, state
                events.emit "hue.light.state", id, state

            callback err, results if callback?

    # Turn all lights on (true) or off (false).
    switchAllLights: (turnOn, callback) =>
        logger.debug "Hue.switchAllLights", turnOn
        @setLightState @getLightIds(), {on: turnOn}, callback

    # Turn the specified light on (true) or off (false).
    switchLight: (id, turnOn, callback) =>
        logger.debug "Hue.switchLight", id, turnOn
        @setLightState id, {on: turnOn}, callback

    # JOBS
    # -------------------------------------------------------------------------

    # Scheduled job to refresh the hub data.
    jobRefreshHub: =>
        @refreshHub()


# Singleton implementation.
# -----------------------------------------------------------------------------
Hue.getInstance = ->
    @instance = new Hue() if not @instance?
    return @instance

module.exports = exports = Hue.getInstance()