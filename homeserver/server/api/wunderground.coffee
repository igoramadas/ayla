# WEATHER UNDERGROUND API
# -----------------------------------------------------------------------------
# Access to Weather Underground data. You must define the default location and
# closest station IDs on the settings (recommended 2 or 3 stations).
# More info at http://www.wunderground.com/weather/api
class Wunderground extends (require "./baseApi.coffee")

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
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
            @getConditions()
            @getForecast()
            @getAstronomy()

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

        tasks = []
        reqUrl = "#{settings.wunderground.api.url}#{settings.wunderground.api.clientId}/#{path}/q/"

        # Set queries based on params (default or stationIds).
        # If `stationIds` is set, add pws: to the URL.
        if params?.stationIds?
            reqUrl += "pws:"
            queries = params.stationIds
        else if params?.query?
            queries = [params.query]
        else
            queries = [settings.wunderground.defaultQuery]

        # Iterate queries and create a HTTP request for each.
        for q in queries
            do (q) =>
                task = (cb) => @makeRequest reqUrl + "#{q}.json", cb
                tasks.push task

        # Run tasks in parallel.
        async.parallelLimit tasks, settings.general.parallelTasksLimit, (err, results) =>
            callback err, results if callback?

    # Helper to get average data from different stations.
    getAverageResult: (data, field) =>
        result = {}

        # Iterate data and get average values.
        for d in data
            for prop in settings.wunderground.resultFields
                try
                    if d[field][prop]?
                        curValue = result[prop]
                        nextValue = d[field][prop].toString()

                        # Parse next value.
                        if nextValue.indexOf("%") >= 0
                            nextValue = nextValue.replace "%", ""
                        if not isNaN nextValue
                            nextValue = parseFloat nextValue

                        # Set result data.
                        if not curValue? or curValue is ""
                            result[prop] = nextValue
                        else
                            if not isNaN curValue
                                result[prop] = ((curValue + nextValue) / 2).toFixed(2)
                            else if curValue.toString().indexOf(nextValue) < 0
                                result[prop] += ", " + nextValue
                catch ex
                    @logError "Wunderground.getAverageResult", ex

        # Return result.
        return result

    # GET WEATHER DATA
    # -------------------------------------------------------------------------

    # Get the current weather conditions. If not filter is specified,
    # use default stations from settings.netatmo.stationIds.
    getConditions: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = {stationIds: settings.wunderground.stationIds}

        @apiRequest "conditions", filter, (err, results) =>
            if err?
                @logError "Wunderground.getConditions", err
            else
                currentConditions = @getAverageResult results, "current_observation"
                @setData "current", currentConditions

            callback err, currentConditions if callback?

    # Get the weather forecast for the next 3 days. If not filter is specified,
    # use default location from settings.netatmo.defaultQuery.
    getForecast: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null

        @apiRequest "forecast", filter, (err, results) =>
            if err?
                @logError "Wunderground.getForecast", err
            else
                currentConditions = @getAverageResult results, "forecast"
                @setData "current", currentConditions

            callback err, currentConditions if callback?

    # Get sunrise and sunset hours and other astronomy details for today. If not filter
    # is specified, use default location from settings.netatmo.defaultQuery.
    getAstronomy: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null

        @apiRequest "astronomy", filter, (err, result) =>
            if err?
                @logError "Wunderground.getAstronomy", err
            else
                astronomy = result[0].moon_phase
                @setData "astronomy", astronomy

            callback err, astronomy if callback?

    # JOBS
    # -------------------------------------------------------------------------

    # Refresh current weather conditions.
    jobGetConditions: =>
        logger.info "Netatmo.jobGetConditions"

        @getConditions()

    # Refresh weather forecast.
    jobGetForecast: =>
        logger.info "Netatmo.jobGetWeather"

        @getForecast()

    # Refresh astronomy related data.
    jobGetAstronomy: =>
        logger.info "Netatmo.jobGetAstronomy"

        @getAstronomy()


# Singleton implementation.
# -----------------------------------------------------------------------------
Wunderground.getInstance = ->
    @instance = new Wunderground() if not @instance?
    return @instance

module.exports = exports = Wunderground.getInstance()