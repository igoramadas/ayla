# WEATHER UNDERGROUND API
# -----------------------------------------------------------------------------
class Wunderground extends (require "./apiBase.coffee")

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    http = require "http"
    lodash = require "lodash"
    moment = require "moment"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Wunderground module.
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

    # Helper to make requests to Weather Underground for stations defined on the settings.
    # The callback result will be the average of station data.
    apiRequest: (path, callback) =>
        tasks = []

        # Iterate stations and create a HTTP request for each station.
        for id in settings.wunderground.stationIds
            do (id) ->
                task = (cb) ->
                    reqUrl = settings.wunderground.api.url + settings.wunderground.api.clientId + "/#{path}/q/pws:#{id}.json"
                    @makeRequest reqUrl, null, cb

                # Add task and debug log.
                tasks.push task

        # Run tasks in parallel.
        async.parallelLimit tasks, settings.general.parallelLimit, (err, results) =>
            if err?
                logger.error "Wunderground.apiRequest", path, err
            else
                logger.debug "Wunderground.apiRequest", path, results

            callback err, results if callback?

    # Helper to get average data from different stations.
    getAverageResult: (data, field, callback) =>
        if not callback?
            throw new Error "The callback for getAverageResult must be specified."

        result = {}

        # Iterate data and get average values.
        for d in data
            for prop in settings.wunderground.resultFields
                curValue = result[prop]
                nextValue = d[field][prop]

                # Parse next value.
                if nextValue.toString().indexOf("%") > 0
                    nextValue = nextValue.toString().replace "%", ""
                if not isNaN nextValue
                    nextValue = parseFloat nextValue

                # Set result data.
                if not curValue?
                    result[prop] = nextValue
                else
                    if lodash.isNumber nextValue
                        result[prop] = (curValue + nextValue) / 2
                    else if curValue.indexOf(nextValue) < 0
                        result[prop] += ", " + nextValue

        callback null, result

    # GET WEATHER DATA
    # -------------------------------------------------------------------------

    # Get the current weather conditions.
    getCurrentWeather: (callback) =>
        @apiRequest "conditions", (err, results) =>
            if err?
                callback err
            else
                @getAverageResult results, "current_observation", callback

    # JOBS
    # -------------------------------------------------------------------------

    # Refresh weather data and save to the database.
    jobRefreshWeather: =>


# Singleton implementation.
# -----------------------------------------------------------------------------
Wunderground.getInstance = ->
    @instance = new Wunderground() if not @instance?
    return @instance

module.exports = exports = Wunderground.getInstance()