# NETATMO API
# -----------------------------------------------------------------------------
class Netatmo extends (require "./baseApi.coffee")

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    data = require "../data.coffee"
    lodash = require "lodash"
    moment = require "moment"
    querystring = require "querystring"
    security = require "../security.coffee"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Stores the current indoor and outdoor readings.
    currentReadings: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the Netatmo module.
    init: =>
        @baseInit()

    # Start collecting weather data.
    start: =>
        @baseStart()

        # Load outdoor on start.
        @getOutdoorMeasure (err, result) =>
            if err?
                logger.error "Netatmo.init", "getOutdoorMeasure", err

        # Load indoor on start.
        @getIndoorMeasure (err, result) =>
            if err?
                logger.error "Netatmo.init", "getIndoorMeasure", err

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

    # Check if the returned results or parameters represent the current reading.
    isCurrent = (params) ->
        if params["date_end"] is "last"
            return true
        return false

    # Get outdoor readings from Netatmo. Default is to get only the most current data.
    getOutdoorMeasure: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null

        # Set outdoor parameters.
        params = getParams filter
        params["type"] = "Temperature,Humidity"

        # Make the request for outdoor readings.
        @makeRequest "getmeasure", params, (err, result) =>
            if err?
                logger.error "Netatmo.getIndoorMeasure", filter, err
            else
                logger.debug "Netatmo.getIndoorMeasure", filter

                # Result represent current readings?
                if isCurrent params
                    data.upsert "netatmo-outdoor"

            callback err, result

    # Get indoor readings from Netatmo. Default is to get only the most current data.
    getIndoorMeasure: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null

        # Set indoor parameters.
        params = getParams filter
        params["type"] = "Temperature,Humidity,Pressure,CO2,Noise"

        # Make the request for indoor readings.
        @makeRequest "getmeasure", params, (err, result) =>
            if err?
                logger.error "Netatmo.getIndoorMeasure", filter, err
            else
                logger.debug "Netatmo.getIndoorMeasure", filter

                # Result represent current readings?
                if isCurrent params
                    data.upsert "netatmo-indoor", result

            callback err, result

    # PAGES
    # -------------------------------------------------------------------------

    # Get Netatmo dashboard data.
    getDashboard: (callback) =>
        getOutdoor = (cb) => @getOutdoorMeasure (err, result) -> cb err, {outdoor: result}
        getIndoor = (cb) => @getIndoorMeasure (err, result) -> cb err, {indoor: result}

        async.parallel [getOutdoor, getIndoor], (err, result) =>
            callback err, result

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