# FITBIT API
# -----------------------------------------------------------------------------
# Module for activities, sleep and body data using Fitbit trackers.
# More info at http://dev.fitbit.com
class Fitbit extends (require "./baseApi.coffee")

    expresser = require "expresser"
    database= expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Fitbit module.
    init: =>
        @baseInit()

    # Start the Fitbit module.
    start: =>
        @oauthInit (err, result) =>
            if err?
                @logError "Fitbit.start", err
            else
                @baseStart()

                if settings.modules.getDataOnStart and result.length > 0
                    @getSleep()
                    @getActivities()
                    @getBody()

    # Stop the Fitbit module.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Fitbit API.
    apiRequest: (path, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth.client]
            callback "Module not running or OAuth client not ready. Please check Fitbit API settings." if callback?
            return

        # Set full request URL.
        reqUrl = settings.fitbit.api.url + path
        reqUrl += "?" + params if params?

        logger.debug "Fitbit.apiRequest", reqUrl

        # Make request using OAuth.
        @oauth.get reqUrl, (err, result) ->
            result = JSON.parse result if lodash.isString result
            callback err, result if lodash.isFunction callback

    # SLEEP DATA
    # -------------------------------------------------------------------------

    # Get sleep data for the specified filter / date, or for yesterday
    # if no `date` is provided. If filter is a number, get date for today
    # minus filter in days.
    getSleep: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        # Parse date and set filter.
        if not filter?
            date = moment().subtract("d", 1).format settings.fitbit.dateFormat
        else if lodash.isNumber filter
            date = moment().subtract("d", filter).format settings.fitbit.dateFormat
        else if filter.date?
            date = filter?.date
        else
            date = filter

        filter = {date: date}

        # Request sleep data.
        @apiRequest "user/-/sleep/date/#{date}.json", (err, result) =>
            if err?
                @logError "Fitbit.getSleep", filter, err
            else
                @setData "sleep", result, filter

            callback err, result if lodash.isFunction callback

    # ACTIVITIES DATA
    # -------------------------------------------------------------------------

    # Get activity data (steps, calories, etc) for the specified filter / date,
    # or yesterday if no `date` is provided.
    getActivities: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        # Parse date and set filter.
        if not filter?
            date = moment().subtract("d", 1).format settings.fitbit.dateFormat
        else if not isNaN filter
            date = moment().subtract("d", filter).format settings.fitbit.dateFormat
        else if filter.date?
            date = filter?.date
        else
            date = filter

        filter = {date: date}

        # Request activities data.
        @apiRequest "user/-/activities/date/#{date}.json", (err, result) =>
            if err?
                @logError "Fitbit.getActivities", filter, err
            else
                @setData "activities", result, filter

            callback err, result if lodash.isFunction callback

    # BODY DATA
    # -------------------------------------------------------------------------

    # Get weight and body fat data for the specified date range.
    # If no `startDate` and `endDate` are passed then get data for the past week.
    # If passed filter is a number, get body for today minus filter in days.
    getBody: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null

        # Parse dates and set filter.
        if not filter?
            startDate = moment().subtract("w", 1).format settings.fitbit.dateFormat
            endDate = moment().format settings.fitbit.dateFormat
        else if not isNaN filter
            startDate = moment().subtract("d", filter).format settings.fitbit.dateFormat
            endDate = moment().format settings.fitbit.dateFormat
        else
            startDate = filter.startDate
            endDate = filter.endDate

        filter = {startDate: startDate, endDate: endDate}

        # There are 2 API requests, one for weight and one for fat.
        tasks = []
        tasks.push (cb) => @apiRequest "user/-/body/log/weight/date/#{startDate}/#{endDate}.json", (err, result) => cb err, result
        tasks.push (cb) => @apiRequest "user/-/body/log/fat/date/#{startDate}/#{endDate}.json", (err, result) => cb err, result

        # Get body weight and fat using async.
        async.parallelLimit tasks, settings.general.parallelTasksLimit, (err, results) =>
            if err?
                @logError "Fitbit.getBody", filter, err
            else
                results = lodash.merge results[0], results[1]
                @setData "body", results, filter

            callback err, results if callback?


# Singleton implementation.
# -----------------------------------------------------------------------------
Fitbit.getInstance = ->
    @instance = new Fitbit() if not @instance?
    return @instance

module.exports = exports = Fitbit.getInstance()