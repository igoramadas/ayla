# WITHINGS API
# -----------------------------------------------------------------------------
# Module to get weight, body fat and air quality data from Withings Healthmate.
# At the moment activity data (from Pulse) is not supported.
# More info at http://www.withings.com/en/api.
class Withings extends (require "./baseapi.coffee")

    expresser = require "expresser"

    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    querystring = require "querystring"
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the Withings module.
    init: =>
        @baseInit()

    # Start collecting fitness and health data from Withings.
    start: =>
        @baseStart()

        @oauthInit (err, result) =>
            if err?
                @logError "Withings.start", err
            else
                @oauth.client?.setClientOptions {requestTokenHttpMethod: "GET", accessTokenHttpMethod: "GET"}

    # Stop collecting fitness and health data from Withings.
    stop: =>
        @baseStop()

    # Load initial data, usually called when module has authenticated.
    getInitialData: =>
        return if @initialDataLoaded

        @initialDataLoaded = true

        @getBodyMeasures()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Withings API.
    apiRequest: (urlpath, action, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth.authenticated]
            callback "Module not running or OAuth client not ready. Please check Withings API settings."
            return

        # Set request URL and parameters.
        userid = @oauth.data.userId
        reqUrl = settings.withings.api.url + urlpath + "?action=#{action}&userid=#{userid}"
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

    # Get body measures for the specified date. If not date is specified then get
    # for the last 30 days (or whatever is set for recentDays on settings).
    getBodyMeasures: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback

        # Properly parse the filter.
        filter = {} if not filter?
        filter.startdate = moment().subtract(settings.withings.recentDays, "d").unix() if not filter.startdate?
        filter.enddate = moment().unix() if not filter.enddate?

        @apiRequest "measure", "getmeas", filter, (err, result, resp) =>
            if err?
                @logError "Withings.getBodyMeasures", filter, err
            else if result?.status > 0
                @logError "Withings.getBodyMeasures", "Invalid response!", result.status, filter
            else
                @setData "bodyMeasures", result, filter

            callback err, result if hasCallback

    # Get recent body measures, using the `recentDays` setting.
    getRecentBodyMeasures: (callback) =>
        hasCallback = lodash.isFunction callback

        startdate = moment().subtract(settings.withings.recentDays, "d").unix()
        enddate = moment().unix()
        filter = {startdate: startdate, enddate: enddate}

        @getBodyMeasures filter, (err, result) =>
            @setData "recentBodyMeasures", result if result?
            callback err, result if hasCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
Withings.getInstance = ->
    @instance = new Withings() if not @instance?
    return @instance

module.exports = exports = Withings.getInstance()
