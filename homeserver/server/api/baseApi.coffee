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
        if settings[@moduleId].api
            @oauth = new (require "../oauth.coffee") @moduleId
            @oauth.loadTokens callback
        else
            callback "API settings for #{@moduleName} not found." if callback?

    # GENERAL METHODS
    # -------------------------------------------------------------------------

    # Helper to check if module is running and with necessary settings defined.
    isRunning: (requiredObjects) =>
        return false if not @running

        if lodash.isArray requiredObjects
            for i in requiredObjects
                return false if not i?

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
                        body = JSON.parse body

                    # Check for error on response.
                    if body.error?
                        respError = body.error
                    else if body[0]?.error?
                        respError = body[0].error

                    callback respError, body
                catch ex
                    callback {exception: ex, url: reqUrl, params: params}

    # Helper to get filter from a job. Used by most of API modules to properly handle
    # the filter argument (which can be passed directly or via the `args` property
    # of a scheduled cron job).
    getFilterArgs: (filterOrJob) =>
        return null if not filterOrJob?
        return filterOrJob.args if filterOrJob.args?
        return filterOrJob

    # Helper to return a callback URL for the current API module.
    getCallbackUrl: (urlPath) =>
        baseUrl = settings.general.appUrl + @moduleId
        atoken = settings.accessTokens[@moduleId]
        return baseUrl  + "/" + urlPath + "?atoken=" + atoken


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseApi