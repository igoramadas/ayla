# NETATMO API
# -----------------------------------------------------------------------------
class Netatmo extends (require "./baseApi.coffee")

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

    # Init the Netatmo module.
    init: =>
        @baseInit()

    # Start collecting weather data.
    start: =>
        @baseStart()

    # Stop collecting weather data.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Authentication helper for Netatmo.
    auth: (req, res) =>
        security.processAuthToken "netatmo", req, res

    # Make a request to the Netatmo API.
    makeRequest: (path, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get data from the security module and set request URL.
        authCache = security.authCache["netatmo"]
        reqUrl = settings.netatmo.api.url + path + "?"

        # Set default parameters.
        params = {} if not params?
        params.optimize = false

        # Add parameters to request URL.
        reqUrl += querystring.stringify params

        logger.debug "Netatmo.makeRequest", reqUrl, authCache.data.token, authCache.data.tokenSecret

        # Make request using OAuth.
        authCache.oauth.get reqUrl, authCache.data.token, authCache.data.tokenSecret, callback

    # GET DATA
    # -------------------------------------------------------------------------

    # Get indoor readings from Netatmo. Default is to get only the most current data.
    getIndoorMeasure: (filter, callback) =>
        params = {}
        params.type = filter.type || "Temperature,Humidity,Pressure,CO2,Noise"
        params.scale = filter.scale || "30min"
        params.date_begin = filter.startDate if filter.startDate?
        params.date_end = filter.endDate || "last"

        @makeRequest "getmeasure", params, (err, result) =>
            if err?
                logger.error "Netatmo.getWeight", filter, err
            else
                logger.debug "Netatmo.getWeight", filter
            callback err, result

    # PAGES
    # -------------------------------------------------------------------------

    # Get Netatmo dashboard data.
    getDashboard: (callback) =>
        @getIndoorMeasure {}, (err, result) =>
            console.warn err, result

# Singleton implementation.
# -----------------------------------------------------------------------------
Netatmo.getInstance = ->
    @instance = new Netatmo() if not @instance?
    return @instance

module.exports = exports = Netatmo.getInstance()