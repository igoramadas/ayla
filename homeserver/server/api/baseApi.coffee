# BASE API
# -----------------------------------------------------------------------------
# All API modules (files under /api) inherit from this BaseApi.
class BaseApi extends (require "../baseModule.coffee")

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    path = require "path"
    request = require "request"
    url = require "url"

    # AUTH HANDLING
    # -------------------------------------------------------------------------

    # Helper to create an OAuth object.
    oauthInit: (callback) =>
        @oauth = new (require "../oauth.coffee") @moduleId
        @oauth.loadTokens callback

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

        # Value must be a object! If not passed as object, create one with {value: value}.
        value = {value: value} if lodash.isString value or lodash.isNumber value

        # Set default options to emit sockets and save to db.
        options = {} if not options?
        options = lodash.defaults options, {eventsEmit: true, socketsEmit: true, saveToDatabase: true}

        # Emit new data to central event dispatched?
        if options.eventsEmit
            events.emit "#{@moduleId}.data", key, value
            events.emit "#{@moduleId}.data.#{key}", value

        # Emit new data to clients using Sockets?
        if options.socketsEmit
            sockets.emit "#{@moduleId}.data", key, value
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
                    callback {exception: ex, url: reqUrl, params: params}

    # Helper to return a callback URL for the current API module.
    getCallbackUrl: (urlPath) =>
        baseUrl = settings.general.appUrl + @moduleId
        atoken = settings.accessTokens[@moduleId]
        return baseUrl  + "/" + urlPath + "?atoken=" + atoken




# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseApi