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

        logger.debug "Netatmo.makeRequest", reqUrl

        # Make request using OAuth.
        authCache.oauth.get reqUrl, authCache.data.accessToken, callback

    # GET DATA
    # -------------------------------------------------------------------------

    # Helper to get API request parameters based on the filter.
    getParams = (filter) ->
        params = {"device_id": settings.netatmo.deviceId}
        params["scale"] = filter.scale or "30min"
        params["date_end"] = filter.endDate or "last"
        params["date_begin"] = filter.startDate if filter.startDate?

        return params

    # Get outdoor readings from Netatmo. Default is to get only the most current data.
    getOutdoorMeasure: (filter, callback) =>
        params = getParams filter
        params["type"] = "Temperature,Humidity"

        @makeRequest "getmeasure", params, (err, result) =>
            if err?
                logger.error "Netatmo.getIndoorMeasure", filter, err
            else
                logger.debug "Netatmo.getIndoorMeasure", filter
            callback err, result

    # Get indoor readings from Netatmo. Default is to get only the most current data.
    getIndoorMeasure: (filter, callback) =>
        params = getParams filter
        params["type"] = "Temperature,Humidity,Pressure,CO2,Noise"

        @makeRequest "getmeasure", params, (err, result) =>
            if err?
                logger.error "Netatmo.getIndoorMeasure", filter, err
            else
                logger.debug "Netatmo.getIndoorMeasure", filter
            callback err, result

    # PAGES
    # -------------------------------------------------------------------------

    # Get Netatmo dashboard data.
    getDashboard: (callback) =>
        @getIndoorMeasure {}, (err, result) =>
            console.warn err, result

    # JOBS
    # -------------------------------------------------------------------------

    # Get current outdoor conditions (weather) every 30 minutes.
    jobGetOutdoor: (callback) =>
        @getOutdoorMeasure {}, (err, result) =>
            console.warn err, result

    # Get current indoor conditions every 5 minutes.
    jobGetIndoor: (callback) =>
        @getIndoorMeasure {}, (err, result) =>
            console.warn err, result

# Singleton implementation.
# -----------------------------------------------------------------------------
Netatmo.getInstance = ->
    @instance = new Netatmo() if not @instance?
    return @instance

module.exports = exports = Netatmo.getInstance()