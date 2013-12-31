# PHILIPS HUE API
# -----------------------------------------------------------------------------
class Hue extends (require "./apiBase.coffee")

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    data = require "../data.coffee"
    lodash = require "lodash"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds current information about the Hue hub (lights, groups, etc).
    hub: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the Hue module and schedule a job to refresh the hub status every minute.
    init: =>
        @baseInit()

    # Start the module and refresh the Hue hub data.
    start: =>
        @baseStart()
        @refreshHub()

    # Stop the module and cancel the Hue hub refresh jobs.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to get all lights IDs.
    getLightIds: =>
        result = []
        result.push i for i of @hue.lights
        return result

    # Make a request to the Hue API.
    apiRequest: (urlPath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        # Set full URL and make the HTTP request.
        reqUrl = settings.hue.apiUrl + settings.hue.apiUser + "/" + urlPath
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
                @hue = results

                data.upsert "hue", @hue
                logger.info "Hue.refreshHub", "OK"

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