# WEATHER UNDERGROUND API
# -----------------------------------------------------------------------------
# Access to Weather Underground data. You must define the default location on
# the settings.wunderground.defaultQuery, using the pattern Country/CityName.
# More info at http://www.wunderground.com/weather/api
class Wunderground extends (require "./baseapi.coffee")

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Wunderground module.
    init: =>
        @baseInit()

    # Start collecting Wunderground data.
    start: =>
        if not settings.wunderground?.api?.clientId?
            @logError "Wunderground.start", "API clientId for Wunderground not found."
        else if not settings.wunderground?.defaultQuery?
            @logError "Wunderground.start", "The defaultQuery setting for Wunderground was not set."
        else
            @baseStart()

            if settings.modules.getDataOnStart
                @getAstronomy()
                @getConditions()
                @getForecast()

    # Stop collecting Wunderground data.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to make requests to Weather Underground. Accepts a query
    # or an stationIds as parameter / options. The callback result will
    # be the average of station data (if multiple station IDs).
    apiRequest: (path, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = {}

        if not @isRunning [settings.wunderground.api]
            callback "Wunderground API is not set, please check the settings." if callback?
            return

        reqUrl = "#{settings.wunderground.api.url}#{settings.wunderground.api.clientId}/#{path}/q/"

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
            callback err, result if lodash.isFunction callback

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
                @logError "Wunderground.getConditions", err
            else
                result = result.current_observation
                @setData "conditions", result, filter

            callback err, result if lodash.isFunction callback

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
                @logError "Wunderground.getForecast", err
            else
                result = result.forecast?.simpleforecast
                @setData "forecast", result, filter

            callback err, result if lodash.isFunction callback

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
                @logError "Wunderground.getAstronomy", err
            else
                result = result.moon_phase
                @setData "astronomy", result, filter

            callback err, result if lodash.isFunction callback

# Singleton implementation.
# -----------------------------------------------------------------------------
Wunderground.getInstance = ->
    @instance = new Wunderground() if not @instance?
    return @instance

module.exports = exports = Wunderground.getInstance()