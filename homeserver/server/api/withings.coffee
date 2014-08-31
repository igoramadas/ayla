# WITHINGS API
# -----------------------------------------------------------------------------
# Module to get weight, body fat and air quality data from Withings smart scales.
# More info at http://www.withings.com/en/api
class Withings extends (require "./baseapi.coffee")

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    querystring = require "querystring"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Withings module.
    init: =>
        @baseInit()

    # Start collecting fitness and health data from Withings.
    start: =>
        @oauthInit (err, result) =>
            if err?
                @logError "Withings.start", err
            else
                @baseStart()
                @oauth.client?.setClientOptions {requestTokenHttpMethod: "GET", accessTokenHttpMethod: "GET"}

                if settings.modules.getDataOnStart and result.length > 0
                    @getBodyMeasures()

    # Stop collecting fitness and health data from Withings.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Authentication helper for Withings.
    auth: (req, res) =>
        security.processAuthToken "withings", req, res

    # Make a request to the Withings API.
    apiRequest: (path, action, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth, @oauth.client]
            callback "Module not running or OAuth client not ready. Please check Withings API settings." if callback?
            return

        # Set request URL and parameters.
        userid = @oauth.data.userId
        reqUrl = settings.withings.api.url + path + "?action=#{action}&userid=#{userid}"
        reqUrl = reqUrl + "&" + querystring.stringify params if params?

        # Withings expect OAuth parameters to be passed via querystring so we need to hack around here.
        oauthParams = @oauth.client._prepareParameters @oauth.data.token, @oauth.data.tokenSecret, "GET", reqUrl

        # Process and add OAuth params to the URL.
        for p in oauthParams
            if p[0] is "oauth_signature"
                p[1] = encodeURIComponent p[1]
            if p[0].substring(0, 5) is "oauth"
                reqUrl += "&" + p[0] + "=" + p[1]

        # Make request using OAuth.
        @makeRequest reqUrl, (err, result) =>
            if result?
                result = JSON.parse(result) if not lodash.isObject result
                err = result if result?.status > 0

            callback err, result

    # GET DATA
    # -------------------------------------------------------------------------

    # Get body measures for the specified date.
    getBodyMeasures: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        # Properly parse the filter.
        filter = {} if not filter?
        filter.startdate = moment().subtract(1, "M").unix() if not filter.startdate?
        filter.enddate = moment().unix() if not filter.enddate?

        @apiRequest "measure", "getmeas", filter, (err, result, resp) =>
            if err?
                logger.error "Withings.getBodyMeasures", filter, err
            else if result?.status > 0
                logger.error "Withings.getBodyMeasures", "Invalid response!", result.status, filter
            else
                @setData "bodymeasures", result, filter
                logger.info "Withings.getBodyMeasures", filter, result

            callback err, result if lodash.isFunction callback

# Singleton implementation.
# -----------------------------------------------------------------------------
Withings.getInstance = ->
    @instance = new Withings() if not @instance?
    return @instance

module.exports = exports = Withings.getInstance()
