# WEATHER UNDERGROUND API
# -----------------------------------------------------------------------------
class Wunderground

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
        logger.debug "Wunderground.init"

    # GET WEATHER DATA
    # -------------------------------------------------------------------------

    # Helper to make requests to Weather Underground for stations defined on the settings.
    # The callback result will be the average of station data.
    makeRequest: (path, callback) =>
        tasks = []

        # Iterate stations and create a HTTP request for each station.
        for id in settings.wunderground.stationIds
            do (id) ->
                task = (cb) ->
                    reqUrl = settings.wunderground.apiUrl + settings.wunderground.apiKey + "/#{path}/q/pws:#{id}.json"
                    req = http.get reqUrl, (response) ->
                        response.downloadedData = ""
                        response.addListener "data", (data) -> response.downloadedData += data
                        response.addListener "end", -> cb null, JSON.parse response.downloadedData

                    # On request error, trigger the callback straight away.
                    req.on "error", (err) -> cb err

                # Add task and debug log.
                tasks.push task
                logger.debug "Wunderground.makeRequest", id

        # Run tasks in parallel.
        async.parallel tasks, (err, results) =>
            if err?
                logger.error "Wunderground.makeRequest", path, err
            else
                logger.debug "Wunderground.makeRequest", path, results
            callback err, results

    # Helper to get average data from different stations.
    getAverageResult: (data, field, callback) =>
        result = {}

        # Iterate data and get average values.
        for d in data
            for prop in settings.wunderground.resultFields
                curValue = result[prop]
                nextValue = d[field][prop]

                # Parse result data.
                if not value?
                    result[prop] = nextValue
                else if lodash.isNumber nextValue
                    result[prop] = (curValue + nextValue) / 2
                else
                    result[prop] += ", " + nextValue

        callback null, result

    # Get the current weather conditions.
    getCurrentWeather: (callback) =>
        @makeRequest "conditions", (err, results) =>
            if err?
                callback err
            else
                @getAverageResult results, "current_conditions", callback


# Singleton implementation.
# -----------------------------------------------------------------------------
Wunderground.getInstance = ->
    @instance = new Wunderground() if not @instance?
    return @instance

module.exports = exports = Wunderground.getInstance()