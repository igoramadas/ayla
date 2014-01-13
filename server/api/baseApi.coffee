# API BASE MODULE
# -----------------------------------------------------------------------------
class ApiBase

    expresser = require "expresser"
    cron = expresser.cron
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    data = require "../data.coffee"
    http = require "http"
    https = require "https"
    lodash = require "lodash"
    moment = require "moment"
    path = require "path"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all downloaded / processed data for that particular module.
    data: {}

    # Holds all errors that happened on the module.
    errors: {}

    # Sets if module is running (true) or suspended (false).
    running: false

    # INIT
    # -------------------------------------------------------------------------

    # Called when the module inits.
    baseInit: =>
        @moduleName = @__proto__.constructor.name.toString()
        @moduleId = @moduleName.toLowerCase()

        # Log and set data.
        logger.debug "#{@moduleName}.init"
        data.cache[@moduleId] = {}

        @start()

    # Called when the module starts.
    baseStart: =>
        @running = true
        cron.start {module: "#{@moduleId}.coffee"}

    # Called when the module stops.
    baseStop: =>
        @running = false
        cron.stop {module: "#{@moduleId}.coffee"}

    # DATA HANDLING
    # -------------------------------------------------------------------------

    # Load data from the database and populate the `data` property.
    loadData: =>
        database.get "data-#{@moduleId}", (err, results) =>
            if err?
                logger.error "#{@moduleName}.loadData", err
            else
                logger.info "#{@moduleName}.loadData", "#{results.length} objects to be loaded."

            # Iterate results.
            for r in results
                @data[r.key] = r.data

            # Trigger load event.
            events.emit "#{@moduleId}.data.load"

    # Save module data.
    setData: (key, value, options) =>
        @data[key] = value

        if not options? or options.saveToDatabase
            database.set "data-#{@moduleId}", {key: key, data: value}, (err, result) =>
                if err?
                    logger.error "#{@moduleName}.setData", key, err
                else
                    logger.debug "#{@moduleName}.setData", key, value

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

            # Append received data.
            response.addListener "data", (data) ->
                response.downloadedData += data

            # On end set the `downloadedData` property as JSON.
            response.addListener "end", =>
                if callback?
                    try
                        response.downloadedData = JSON.parse response.downloadedData

                        # Check for error on response.
                        if response.downloadedData.error?
                            respError = response.downloadedData.error
                        else if response.downloadedData[0]?.error?
                            respError = response.downloadedData[0].error
                        else
                            respError = null

                        callback respError, response.downloadedData
                    catch ex
                        callback ex

        # On request error, trigger the callback straight away.
        req.on "error", (err) ->
            callback {err: err, url: reqUrl, params: params} if callback?

        # Write body, if any, and end request.
        req.write(body, settings.general.encoding) if body?
        req.end()

    # Logs module errors.
    logError: =>
        id = arguments[0]
        args = lodash.toArray arguments

        # Append to the errors log.
        @errors[id] = [] if not @errors[id]?
        @errors[id].push {timestamp: moment().unix(), data: args}
        count = @errors[id].length

        # Too many consecutive errors? Stop the module.
        if count is settings.general.stopOnErrorCount
            logger.critical id, "Too many consecutive errors (#{count}) logged.", "Module will now stop."
            @stop()

        logger.error.apply logger, args


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = ApiBase