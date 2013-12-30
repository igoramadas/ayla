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
    http = require "http"
    lodash = require "lodash"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds current information about all registered lights.
    lights: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the Hue module.
    init: =>
        logger.debug "Hue.init"
        @refreshHub()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Hue API.
    makeRequest: (urlPath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        logger.debug "Hue.makeRequest", reqUrl, urlPath, params

        # Set request URL.
        reqUrl = settings.hue.apiUrl + settings.hue.apiUser + "/" + urlPath
        reqOptions = url.parse reqUrl

        # Set request parameters.
        if params?
            reqOptions.method = params.method
            body = params.body
            body = JSON.stringify body if not lodash.isString params.body
        else
            reqOptions.method = "GET"

        # Make the HTTP request.
        req = http.request reqOptions, (response) ->
                response.downloadedData = ""

                response.addListener "data", (data) =>
                    response.downloadedData += data

                response.addListener "end", =>
                    try
                        callback null, JSON.parse response.downloadedData
                    catch ex
                        callback ex if callback?

        # On request error, trigger the callback straight away.
        req.on "error", (err) => callback err if callback?

        # Write body, if any, and end request.
        req.write body, settings.general.encoding if body?
        req.end()

    # GET HUB DATA
    # -------------------------------------------------------------------------

    # Refresh information from the Hue hub.
    refreshHub: (callback) =>
        logger.debug "Hue.refreshHub"

        @makeRequest "lights", (err, results) =>
            if err?
                @logError "Hue.refreshHub", err
            else
                @lights = results
                data.upsert "hue.lights", results
                logger.info "Hue.refreshHub", "Got #{results.length} lights."

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
            do (i) => tasks.push (cb) => @makeRequest "lights/#{i}/state", params, cb

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
        for i of @lights
            @switchLight i, turnOn, callback

    # Turn the specified light on (true) or off (false).
    switchLight: (id, turnOn, callback) =>
        logger.debug "Hue.switchLight", id, turnOn
        @setLightState id, {on: turnOn}, callback





# Singleton implementation.
# -----------------------------------------------------------------------------
Hue.getInstance = ->
    @instance = new Hue() if not @instance?
    return @instance

module.exports = exports = Hue.getInstance()