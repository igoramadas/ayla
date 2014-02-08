# FITBIT API
# -----------------------------------------------------------------------------
class Fitbit extends (require "./baseApi.coffee")

    expresser = require "expresser"
    database= expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    security = require "../security.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Fitbit module.
    init: =>
        @baseInit()

    # Start the Fitbit module.
    start: =>
        @baseStart()

    # Stop the Fitbit module.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Authentication helper for Fitbit.
    auth: (req, res) =>
        security.processAuthToken "fitbit", req, res

    # Make a request to the Fitbit API.
    apiRequest: (path, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get data from the security module and set request URL.
        authCache = security.authCache["fitbit"]
        reqUrl = settings.fitbit.api.url + path
        reqUrl += "?" + params if params?

        logger.debug "Fitbit.apiRequest", reqUrl

        # Make request using OAuth.
        authCache.oauth.get reqUrl, authCache.data.token, authCache.data.tokenSecret, (err, result) ->
            if err?
                @logError "Fitbit.apiRequest", path, params, err
            else
                logger.debug "Fitbit.apiRequest", path, params, result

            result = JSON.parse result if lodash.isString result
            callback err, result if callback?

    # GET DATA
    # -------------------------------------------------------------------------

    # Helper to check if API results are newer than the current value for the specified key.
    # This is called by the `setCurrent` method below.
    checkCurrent = (results, key) =>
        current = @data[key]
        return null if not current?

        # Iterate results and compare data.
        for r in results[key]
            newValue = r if moment(r.date, settings.fitbit.dateFormat) > moment(current.timestamp)

        return newValue

    # Check if the returned results represent current data for body or sleep.
    setCurrent = (results) =>
        results = [results] if not lodash.isArray results

        for r in results
            newFat = checkCurrent r, "fat" if r.fat?
            newWeight = checkCurrent r, "weight" if r.weight?
            newSleep = checkCurrent r, "sleep" if r.sleep?

            @setData "fat", newFat if newFat?
            @setData "weight", newWeight if newWeight?
            @setData "sleep", newSleep if newSleep?

    # Get activity data (steps, calories, etc) for the specified date, or yesterday if no `date` is provided.
    getActivities: (date, callback) =>
        date = moment().subtract("d", 1).format settings.fitbit.dateFormat if not date?

        @apiRequest "user/-/activities/date/#{date}.json", (err, result) =>
            if not err?
                setCurrent result

            callback err, result if callback?

    # Get sleep data for the specified date, or for yesterday if no `date` is provided.
    getSleep: (date, callback) =>
        date = moment().subtract("d", 1).format settings.fitbit.dateFormat if not date?

        @apiRequest "user/-/sleep/date/#{date}.json", (err, result) =>
            if not err?
                setCurrent result

            callback err, result if callback?

    # Get weight and body fat data for the specified date range.
    # If no `startDate` and `endDate` are passed then get data for the past week.
    getBody: (startDate, endDate, callback) =>
        startDate = moment().subtract("w", 1).format settings.fitbit.dateFormat if not startDate?
        endDate = moment().format settings.fitbit.dateFormat if not endDate?

        # There are 2 API requests, one for weight and one for fat.
        tasks = []
        tasks.push (cb) => @apiRequest "user/-/body/log/weight/date/#{startDate}/#{endDate}.json", (err, result) => cb err, result
        tasks.push (cb) => @apiRequest "user/-/body/log/fat/date/#{startDate}/#{endDate}.json", (err, result) => cb err, result

        # Get body weight and fat using async.
        async.parallelLimit tasks, settings.general.parallelTasksLimit, (err, results) =>
            if not err?
                setCurrent results
            else if callback?
                results = lodash.merge results[0], results[1]
                callback err, results

    # JOBS
    # -------------------------------------------------------------------------

    # Scheduled job to get general fitness data (activities and body) once a day.
    jobCheckGeneralFitness: =>
        @getActivities()
        @getBody()

    # Scheduled job to check for missing Fitbit sleep and weight data once a day.
    jobCheckMissingData: =>
        if @data.weight?.timestamp < moment().subtract("d", settings.fitbit.missingWeightAfterDays).unix()
            events.emit "fitbit.weight.missing", @data.weight

        for d in settings.fitbit.missingSleepDays
            do (d) =>
                date = moment().subtract("d", d).format settings.fitbit.dateFormat

                # Check if user forgot to add sleep data X days ago.
                @getSleep date, (err, result) =>
                    if err?
                        @logError "Fitbit.jobCheckMissingData", "getSleep", date, err
                        return false

                    # Has sleep data? Stop here, otherwise emit missing sleep event.
                    return if result?.sleep?.length > 0
                    events.emit "fitbit.sleep.missing", result

    # PAGES
    # -------------------------------------------------------------------------

    # Get the Fitbit dashboard data.
    getDashboard: (callback) =>
        yesterday = moment().subtract("d", 1).format settings.fitbit.dateFormat
        getSleepYesterday = (cb) => @getSleep yesterday, (err, result) -> cb err, {sleepYesterday: result}
        getActivitiesYesterday = (cb) => @getActivities yesterday, (err, result) -> cb err, {activitiesYesterday: result}

        async.parallel [getSleepYesterday, getActivitiesYesterday], (err, result) =>
            callback err, result

# Singleton implementation.
# -----------------------------------------------------------------------------
Fitbit.getInstance = ->
    @instance = new Fitbit() if not @instance?
    return @instance

module.exports = exports = Fitbit.getInstance()