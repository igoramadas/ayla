# WEATHER UNDERGROUND API
# -----------------------------------------------------------------------------
# Get weather, climate and astronomy data from Weather Underground. You must
# define the default location on `settings.wunderground.defaultQuery` using
# the pattern Country/CityName.
# More info at http://www.wunderground.com/weather/api.
class Wunderground extends (require "./baseapi.coffee")

    expresser = require "expresser"

    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the Wunderground module.
    init: =>
        @baseInit()

    # Start collecting Wunderground data.
    start: =>
        @baseStart()

        events.on "Wunderground.getAstronomy", @getAstronomy
        events.on "Wunderground.getForecast", @getForecast
        events.on "Wunderground.getConditions", @getConditions

        @getAstronomy()
        @getForecast()
        @getConditions()

    # Stop collecting Wunderground data.
    stop: =>
        @baseStop()

        events.off "Wunderground.getAstronomy", @getAstronomy
        events.off "Wunderground.getForecast", @getForecast
        events.off "Wunderground.getConditions", @getConditions

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to make requests to Weather Underground. Accepts a query
    # or an stationIds as parameter / options. The callback result will
    # be the average of station data (if multiple station IDs).
    apiRequest: (urlpath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = {}

        if not @isRunning [settings.wunderground?.api]
            errMsg = "Wunderground API details not defined, please check settings.wunderground.api."

            if lodash.isFunction callback
                callback errMsg
            else
                logger.warn "Wunderground.apiRequest", errMsg
            return

        reqUrl = "#{settings.wunderground.api.url}#{settings.wunderground.api.clientId}/#{urlpath}/q/"

        # Set queries based on params (query or stationId).
        # If `stationId` is set, add pws: to the URL.
        if params?.stationId?
            reqUrl += "pws:"
            q = params.stationId
        else if params?.query?
            q = params.query
        else
            q = settings.wunderground.defaultQuery

        @makeRequest reqUrl + "#{q}.json", (err, result) =>
            callback err, result

    # GET WEATHER DATA
    # -------------------------------------------------------------------------

    # Get the current weather conditions. If not filter is specified,
    # use default location from settings.netatmo.defaultQuery.
    getConditions: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        @apiRequest "conditions", filter, (err, result) =>
            if err?
                logger.error "Wunderground.getConditions", err
            else
                result = result.current_observation
                @setData "conditions", result, filter

            callback? err, result

    # Get the weather forecast for the next 3 days. If not filter is specified,
    # use default location from settings.netatmo.defaultQuery.
    getForecast: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        @apiRequest "forecast", filter, (err, result) =>
            if err?
                logger.error "Wunderground.getForecast", err
            else
                result = result.forecast?.simpleforecast
                @setData "forecast", result, filter

            callback? err, result

    # Get sunrise and sunset hours and other astronomy details for today. If not filter
    # is specified, use default location from settings.netatmo.defaultQuery.
    getAstronomy: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        @apiRequest "astronomy", filter, (err, result) =>
            if err?
                logger.error "Wunderground.getAstronomy", err
            else
                result = result.moon_phase
                @setData "astronomy", result, filter

            callback? err, result

# Singleton implementation.
# -----------------------------------------------------------------------------
Wunderground.getInstance = ->
    @instance = new Wunderground() if not @instance?
    return @instance

module.exports = exports = Wunderground.getInstance()
