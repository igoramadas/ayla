# WITHINGS API
# -----------------------------------------------------------------------------
# Module to get weight, body fat and air quality data from Withings smart scales.
# More info at http://www.withings.com/en/api
class Withings extends (require "./baseApi.coffee")

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
                @oauth.client.setClientOptions {requestTokenHttpMethod: "GET", accessTokenHttpMethod: "GET"}

                if settings.modules.getDataOnStart and result.length > 0
                    @getWeight()

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
        userid = @oauth.data[@oauth.defaultUser].userId
        reqUrl = settings.withings.api.url + path + "?action=#{action}&userid=#{userid}"
        reqUrl = reqUrl + "&" + querystring.stringify params if params?

        # Make request using OAuth.
        @oauth.client.post reqUrl, @oauth.data.token, @oauth.data.tokenSecret, (err, result) =>
            if result?
                result = JSON.parse(result) if not lodash.isObject result
                err = result if result?.status > 0

            callback err, result

    # GET DATA
    # -------------------------------------------------------------------------

    # Get weight data for the specified date.
    getWeight: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        # Properly parse the filter.
        filter = {} if not filter?
        filter.startdate = moment().subtract("M", 1).unix() if not filter.startdate?
        filter.enddate = moment().unix() if not filter.enddate?

        @apiRequest "measure", "getmeas", filter, (err, result, resp) =>
            if err?
                logger.error "Withings.getWeight", filter, err
            else if result?.status > 0
                logger.error "Withings.getWeight", "Invalid response!", result.status, filter
            else
                @setData "weight", result, filter
                logger.info "Withings.getWeight", filter, result

            callback err, result if lodash.isFunction callback


# Singleton implementation.
# -----------------------------------------------------------------------------
Withings.getInstance = ->
    @instance = new Withings() if not @instance?
    return @instance

module.exports = exports = Withings.getInstance()
