# PHILIPS HUE API
# -----------------------------------------------------------------------------
class Hue extends (require "./apiBase.coffee")

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

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
        req = http.request reqOptions, (response) =>
                response.downloadedData = ""

                response.addListener "data", (data) =>
                    response.downloadedData += data

                response.addListener "end", =>
                    try
                        callback null, JSON.parse response.downloadedData
                    catch ex
                        callback ex if callback?

        # On request error, trigger the callback straight away.
        req.on "error", (err) =>
            callback err if callback?

        # Write body, if any, and end request.
        req.write(body, settings.general.encoding) if body?
        req.end()

    # GET HUB DATA
    # -------------------------------------------------------------------------

    # Refresh information from the Hue hub.
    refreshHub: =>
        logger.info "Hue.refreshHub"

        @makeRequest "lights", (err, results) =>
            if err?
                @logError "Hue.refreshHub", err
            else
                @lights = results
                data.upsert "hue.lights", results

    # LIGHT CONTROL
    # -------------------------------------------------------------------------

    # Turn lights on (true) or off (false). If no `id` is specified then
    # execute the command for all lights.
    switchLight: (id, turnOn, callback) =>
        if lodash.isFunction turnOn
            callback = turnOn

        if lodash.isBoolean id
            turnOn = id
            id = null

        # Create the iterator array.
        if id?
            arr = {}
            arr[id] = @lights[id]
        else
            id = "All"
            arr = @lights

        logger.debug "Hue.switchLight", id, turnOn

        # Set request parameter to use PUT and pass the `on` property.
        params = {method: "PUT", body: {on: turnOn}}

        # Make the API request for the specified or all lights.
        for i of @lights
            do (i) =>
                @makeRequest "lights/#{i}/state", params, (err, result) =>
                    if err?
                        @logError "Hue.switchLight", i, turnOn, err
                    else
                        logger.info "Hue.switchLight", i, turnOn, "OK"


# Singleton implementation.
# -----------------------------------------------------------------------------
Hue.getInstance = ->
    @instance = new Hue() if not @instance?
    return @instance

module.exports = exports = Hue.getInstance()