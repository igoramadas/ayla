# API BASE MODULE
# -----------------------------------------------------------------------------
class ApiBase

    expresser = require "expresser"
    cron = expresser.cron
    logger = expresser.logger

    http = require "http"
    https = require "https"
    path = require "path"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all errors that happened on the module.
    errors: {}

    # Sets if module is running (true) or suspended (false).
    running: false

    # INIT
    # -------------------------------------------------------------------------

    # Called when the module inits.
    baseInit: =>
        @moduleName = @__proto__.constructor.name.toString()
        logger.debug "#{@moduleName}.init"
        @start()

    # Called when the module starts.
    baseStart: =>
        @running = true
        cron.start {module: "#{@moduleName.toLowerCase()}.coffee"}
        logger.info "#{@moduleName}.start"

    # Called when the module stops.
    baseStop: =>
        @running = false
        cron.stop {module: "#{@moduleName.toLowerCase()}.coffee"}
        logger.info "#{@moduleName}.stop"

    # GENERAL METHODS
    # -------------------------------------------------------------------------

    # Base helper to make HTTP / HTTPS requests.
    makeRequest: (reqUrl, params, callback) =>
        logger.debug "#{@moduleName}.makeHttpRequest", reqUrl, params

        # Set request URL object.
        reqOptions = url.parse reqUrl

        # Set request parameters.
        if params?
            reqOptions.method = params.method || "GET"
            if params.body?
                body = params.body
                body = JSON.stringify body if not lodash.isString body
        else
            reqOptions.method = "GET"

        # Set correct request handler.
        if reqUrl.indexOf("https://") < 0
            httpHandler = http
        else
            httpHandler = https

        # Make the HTTP request.
        req = httpHandler.request reqOptions, (response) ->
            response.downloadedData = ""

            response.addListener "data", (data) =>
                response.downloadedData += data

            response.addListener "end", =>
                if callback?
                    try
                        response.downloadedData = JSON.parse response.downloadedData
                        callback null, response.downloadedData
                    catch ex
                        callback ex

        # On request error, trigger the callback straight away.
        req.on "error", (err) ->
            @logError "#{@moduleName}.makeHttpRequest", reqUrl, params, err
            callback err if callback?

        # Write body, if any, and end request.
        req.write(body, settings.general.encoding) if body?
        req.end()

    # Logs module errors.
    logError: =>
        id = arguments[0]

        @errors[id] = [] if not @errors[id]?
        @errors[id].push arguments

        logger.error.apply logger, arguments


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = ApiBase