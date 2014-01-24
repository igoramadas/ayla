# API BASE MODULE
# -----------------------------------------------------------------------------
class BaseApi

    expresser = require "expresser"
    cron = expresser.cron
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

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

        # Log and start.
        logger.debug "#{@moduleName}.init"
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

        # Set default options to emit sockets and save to db.
        options = {} if not options?
        options = lodash.defaults options, {eventsEmit: true, socketsEmit: true, saveToDatabase: true}

        # Emit new data to central event dispatched?
        if options.eventsEmit
            events.emit "#{@moduleId}.data.#{key}", value

        # Emit new data to clients using Sockets?
        if options.socketsEmit
            sockets.emit "#{@moduleId}.data.#{key}", value

        # Save the new data on the database?
        if options.saveToDatabase
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

        # The `params` is optional.
        if not callback? and lodash.isFunction params
            callback = params
            params = null

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
                        if lodash.isString response.downloadedData
                            response.downloadedData = JSON.parse response.downloadedData

                        # Check for error on response.
                        if response.downloadedData.error?
                            respError = response.downloadedData.error
                        else if response.downloadedData[0]?.error?
                            respError = response.downloadedData[0].error

                        callback respError, response.downloadedData
                    catch ex
                        callback ex

        # On request error, trigger the callback straight away.
        req.on "error", (err) ->
            callback {err: err, url: reqUrl, params: params} if callback?

        # Write body, if any, and end request.
        req.write body, settings.general.encoding if body?
        req.end()

    # Checks if auth data is valid and set. Returns false if not valid.
    checkAuthData: (obj) =>
        if not obj?
            logger.critical "#{@moduleName}.checkAuthData", "Auth data is missing."
            return "Auth data is missing."
        return null

    # Logs module errors.
    logError: =>
        id = arguments[0]
        args = lodash.toArray arguments

        # Append to the errors log.
        @errors[id] = [] if not @errors[id]?
        @errors[id].push {timestamp: moment().unix(), data: args}
        count = @errors[id].length

        # Too many consecutive errors? Stop the module.
        if count is settings.general.moduleStopOnErrorCount
            logger.critical id, "Too many consecutive errors (#{count}) logged.", "Module will now stop."
            @stop()

        logger.error.apply logger, args

    # Helper to clear old errors.
    clearErrors: =>
        maxAge = moment().subtract("h", settings.general.moduleErrorMaxAgeHours).unix()

        # Iterate errors by ID, then internal data, and remove everything which is too old.
        for key, value of @errors
            for d in value
                if d.timestamp < maxAge
                    lodash.remove value, d
            if value.length < 1
                delete @errors[key]


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseApi