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

    lodash = require "lodash"
    moment = require "moment"
    path = require "path"
    request = require "request"
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

        # Create database TTL index.
        expires = settings.database.dataCacheExpireHours * 3600
        database.db.collection("data-#{@moduleId}").ensureIndex {"datestamp": 1}, {expireAfterSeconds: expires}

        # Start cron jobs.
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
            database.set "data-#{@moduleId}", {key: key, data: value, datestamp: new Date()}, (err, result) =>
                if err?
                    logger.error "#{@moduleName}.setData", key, err
                else
                    logger.debug "#{@moduleName}.setData", key, value

    # GENERAL METHODS
    # -------------------------------------------------------------------------

    # Base helper to make HTTP / HTTPS requests.
    makeRequest: (reqUrl, params, callback) =>
        logger.debug "#{@moduleName}.makeRequest", reqUrl, params

        # The `params` is optional.
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Set request URL object.
        reqOptions = {uri: url.parse reqUrl, encoding: settings.general.encoding}

        # Set request parameters.
        if params?
            reqOptions.method = params.method || (if params.body? then "POST" else "GET")
            reqOptions.headers = params.headers || {}

            # Has body? If so, set proper JSON or form data.
            if params.body?
                if params.isForm
                    reqOptions.form = params.body
                else
                    if lodash.isString params.body
                        reqOptions.body = params.body
                    else
                        reqOptions.body = JSON.stringify params.body

                    # Force a specific content type?
                    if params.contentType?
                        reqOptions.headers["Content-Type"] = params.contentType

            # Has cookies?
            if params.cookie?
                reqOptions.headers["Cookie"] = params.cookie

        # No custom parameters? Set default GET request.
        else
            reqOptions.method = "GET"

        # Make the HTTP request.
        request reqOptions, (err, resp, body) =>
            if err?
                callback {err: err, url: reqUrl, params: params} if callback?
                return

            # Has callback?
            if callback?
                try
                    parseJson = not params?.parseJson? or params.parseJson

                    # Do not parse JSON if parseJson is false or response is not a string.
                    if parseJson and lodash.isString body
                        body = JSON.parse body

                    # Check for error on response.
                    if body.error?
                        respError = body.error
                    else if body[0]?.error?
                        respError = body[0].error

                    callback respError, body
                catch ex
                    callback {err: ex, url: reqUrl, params: params}

    # Checks if auth data is valid and set. Returns false if not valid.
    checkAuthData: (obj) =>
        if not obj?
            logger.critical "#{@moduleName}", "Auth data is missing."
            return "Auth data is missing."
        return null

    # Helper to return a callback URL for the current API module.
    getCallbackUrl: (urlPath) =>
        baseUrl = settings.general.appUrl + @moduleId
        atoken = settings.accessTokens[@moduleId]
        return baseUrl  + "/" + urlPath + "?atoken=" + atoken

    # ERRORS
    # -------------------------------------------------------------------------

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