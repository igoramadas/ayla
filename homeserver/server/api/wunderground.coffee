# WEATHER UNDERGROUND API
# -----------------------------------------------------------------------------
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

    # Start collecting weather data.
    start: =>
        @getCurrentWeather()
        @baseStart()

    # Stop collecting weather data.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to make requests to Weather Underground for stations defined on the settings.
    # The callback result will be the average of station data.
    apiRequest: (path, options, callback) =>
        if not settings.wunderground.api?
            logger.warn "Wunderground.apiRequest", "Wundeground API settings are not defined. Abort!"
            return

        if not callback? and lodash.isFunction options
            callback = options
            options = {}

        # Set tasks and stations arrays.
        tasks = []

        # Set queries based on options (default or stationIds).
        if options.stationIds?
            queries = options.stationIds
            reqUrl = settings.wunderground.api.url + settings.wunderground.api.clientId + "/#{path}/q/pws:"
        else
            queries = [settings.wunderground.defaultQuery]
            reqUrl = settings.wunderground.api.url + settings.wunderground.api.clientId + "/#{path}/q/"

        # Iterate stations and create a HTTP request for each station.
        for q in queries
            do (q) =>
                task = (cb) => @makeRequest reqUrl + "#{q}.json", cb

                # Add task and debug log.
                tasks.push task

        # Run tasks in parallel.
        async.parallelLimit tasks, settings.general.parallelTasksLimit, (err, results) =>
            if err?
                @logError "Wunderground.apiRequest", path, err
            else
                logger.debug "Wunderground.apiRequest", path, results

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

    # Get the current weather conditions.
    getCurrentWeather: (callback) =>
        logger.debug "Wunderground.getCurrentWeather"

        @apiRequest "conditions", {stationIds: settings.wunderground.stationIds}, (err, results) =>
            if not err?
                currentConditions = @getAverageResult results, "current_observation"
                @setData "conditions", currentConditions

            callback err, currentConditions if callback?

    # Get sunrise and sunset hours and other astronomy details for today.
    getAstronomy: (callback) =>
        logger.debug "Wunderground.getAstronomy"

        @apiRequest "astronomy", (err, result) =>
            if not err?
                astronomy = result[0].moon_phase
                @setData "astronomy", astronomy

            callback err, astronomy if callback?

    # JOBS
    # -------------------------------------------------------------------------

    # Refresh weather data every few minutes.
    jobGetWeather: =>
        @getCurrentWeather()

    # Refresh astronomy data once a day.
    jobGetAstronomy: =>
        @getAstronomy()


# Singleton implementation.
# -----------------------------------------------------------------------------
Wunderground.getInstance = ->
    @instance = new Wunderground() if not @instance?
    return @instance

module.exports = exports = Wunderground.getInstance()