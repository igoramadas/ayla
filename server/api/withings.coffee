# WITHINGS API
# -----------------------------------------------------------------------------
class Withings

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    lodash = require "lodash"
    moment = require "moment"
    querystring = require "querystring"
    security = require "../security.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Withings module.
    init: =>
        logger.debug "Withings.init"

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
        reqUrl = settings.withings.apiUrl + path

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

        @makeRequest "measure", "getmeas", (err, result, resp) =>
            if err?
                logger.error "Withings.getWeight", startTimestamp, endTimestamp, err
            else
                logger.debug "Withings.getWeight", startTimestamp, endTimestamp, result
            callback err, result

    # PAGES
    # -------------------------------------------------------------------------

    # Get the Fitbit dashboard data.
    getDashboard: (callback) =>
        start = moment().subtract("d", 30).unix()
        end = moment().unix()
        @getWeight start, end, (err, result) =>
            console.warn result


# Singleton implementation.
# -----------------------------------------------------------------------------
Withings.getInstance = ->
    @instance = new Withings() if not @instance?
    return @instance

module.exports = exports = Withings.getInstance()