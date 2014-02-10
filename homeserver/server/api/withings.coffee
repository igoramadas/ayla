# WITHINGS API
# -----------------------------------------------------------------------------
# Module to get weight and air data from Withings smart scales.
# More info at www.withings.com.
class Withings extends (require "./baseApi.coffee")

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # Disable Withings till API gets sorted out.
    disabled: true

    # INIT
    # -------------------------------------------------------------------------

    # Init the Withings module.
    init: =>
        @baseInit()

    # Start collecting fitness and health data from Withings.
    start: =>
        @baseStart()

    # Stop collecting fitness and health data from Withings.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Authentication helper for Withings.
    auth: (req, res) =>
        security.processAuthToken "withings", req, res

    # Make a request to the Withings API.
    makeRequest: (path, action, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get data from the security module and set request URL.
        authCache = security.authCache["withings"]
        reqUrl = settings.withings.api.url + path

        # Set post parameters.
        params = {} if not params?
        params.action = action
        params.userid = authCache.data.userId

        logger.debug "Withings.makeRequest", reqUrl, authCache.data.token, authCache.data.tokenSecret

        # Make request using OAuth.
        authCache.oauth.post reqUrl, authCache.data.token, authCache.data.tokenSecret, params, callback

    # GET DATA
    # -------------------------------------------------------------------------

    # Get weight data for the specified date.
    getWeight: (startTimestamp, endTimestamp, callback) =>
        if not callback?
            throw "Withings.getWeight: parameters date and callback must be specified!"

        # Set defaults.
        startTimestamp = moment().subtract("M", 1).unix() if not startTimestamp?
        endTimestamp = moment().unix() if not endTimestamp?

        params = {startdate: startTimestamp, enddate: endTimestamp}

        @makeRequest "measure", "getmeas", params, (err, result, resp) =>
            if err?
                logger.error "Withings.getWeight", startTimestamp, endTimestamp, err
            else
                logger.debug "Withings.getWeight", startTimestamp, endTimestamp, result

            callback err, result if callback?


# Singleton implementation.
# -----------------------------------------------------------------------------
Withings.getInstance = ->
    @instance = new Withings() if not @instance?
    return @instance

module.exports = exports = Withings.getInstance()