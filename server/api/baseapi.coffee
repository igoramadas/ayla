# BASE API
# -----------------------------------------------------------------------------
# All API modules (files under /api) inherit from this BaseApi.
class BaseApi extends (require "../basemodule.coffee")

    expresser = require "expresser"

    cron = expresser.cron
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    path = require "path"
    request = require "request"
    settings = expresser.settings
    sockets = expresser.sockets
    url = require "url"

    # Enable cron for API modules.
    hasCron: true

    # AUTH HANDLING
    # -------------------------------------------------------------------------

    # Helper to create an OAuth object.
    oauthInit: (callback) =>
        if settings[@moduleNameLower].api
            @oauth = new (require "../oauth.coffee") @moduleNameLower
            @oauth.onAuthenticated = @onAuthenticated if @onAuthenticated?
            @oauth.loadToken callback
        else
            callback? "API settings for #{@moduleName} not found."

    # GENERAL METHODS
    # -------------------------------------------------------------------------

    # Helper to check if module is running and with necessary settings defined.
    isRunning: (requiredObjects) =>
        if lodash.isArray requiredObjects
            for i in requiredObjects
                if not i?
                    logger.debug "#{@moduleName}.isRunning", "One of the requiredObjects is not set.", i
                    return false

        return true

    # Base helper to make HTTP / HTTPS requests.
    makeRequest: (reqUrl, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        logger.debug "#{@moduleName}.makeRequest", reqUrl, params

        # Set request URL object.
        reqOptions = {uri: url.parse reqUrl, encoding: settings.general.encoding}

        # Set request parameters.
        if params?
            reqOptions.method = params.method or (if params.body? then "POST" else "GET")
            reqOptions.headers = params.headers or {}
            reqOptions.auth = params.auth or null

            # Force a specific content type?
            if params.contentType isnt undefined
                reqOptions.headers["Content-Type"] = params.contentType

            # Force a specific encoding
            if params.encoding isnt undefined
                reqOptions.encoding = params.encoding

            # Has body? If so, set proper JSON or form data.
            if params.body?
                if params.isForm
                    reqOptions.form = params.body
                else
                    if lodash.isString params.body
                        reqOptions.body = params.body
                    else
                        reqOptions.body = JSON.stringify params.body

        # No custom parameters? Set default GET request.
        else
            reqOptions.method = "GET"

        # Make the HTTP request.
        request reqOptions, (err, resp, body) =>
            if callback?
                if err?
                    callback {err: err, url: reqUrl, params: params}
                    return

                # Try parsing result body.
                try
                    respError = null
                    parseJson = not params?.parseJson? or params.parseJson

                    # Do not parse JSON if parseJson is false or response is not a string.
                    if parseJson and lodash.isString body
                        if body.toLowerCase().replace("\n", "") is "not found"
                            respError = {error: "Resource not found"}
                        else
                            body = JSON.parse body

                    # Check for error on response.
                    if body.error?
                        respError = body.error
                    else if body[0]?.error?
                        respError = body[0].error

                    callback respError, body
                catch ex
                    callback {exception: ex, body: body, url: reqUrl, params: params}

    # Helper to get the list of scheduled jobs related to this API module.
    getScheduledJobs: =>
        return lodash.where cron.jobs, {module: @moduleName + ".coffee"}

    # Helper to get filter from a job. Used by most of API modules to properly handle
    # the filter argument (which can be passed directly or via the `args` property
    # of a scheduled cron job). If has id and timer, assume it's a job so return null.
    getJobArgs: (argsOrJob) =>
        return null if not argsOrJob?

        if argsOrJob.args?
            return argsOrJob.args
        else if argsOrJob.id? and argsOrJob.callback?
            return null
        else
            return argsOrJob

# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseApi
