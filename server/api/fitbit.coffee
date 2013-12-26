# FITBIT
# -----------------------------------------------------------------------------
class Fitbit

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

    # Init the Fitbit module.
    init: =>
        logger.debug "Fitbit.init"

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Authentication helper for Fitbit.
    auth: (req, res, callback) =>
        security.processAuthToken "fitbit", {version: "1.0"}, req, res

    # Subscribe to Fitbit notifications.
    subscribe: =>
        postUrl = "#{settings.fitbit.apiUrl}user/-/apiSubscriptions/#{user.id}-all.json"

        # Subscribe this application to updates from the user's data
        oauth.post postUrl, token, tokenSecret, null, null, (err, data, res) ->
            if err?
                logger.error "Security.authFitbit", postUrl, err
            callback err, user

    # Make a request to the Fitbit API.
    makeRequest: (path, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get data from the security module and set request URL.
        authCache = security.authCache["fitbit"]
        reqUrl = settings.fitbit.apiUrl + path
        reqUrl += "?" + querystring.stringify params if params?

        # Make request using OAuth.
        authCache.oauth.get reqUrl, authCache.token, authCache.tokenSecret, callback

    # GET DATA
    # -------------------------------------------------------------------------

    # Get sleep data for the specified date.
    getSleep: (date, callback) =>
        if not date? or not callback?
            throw "Fitbit.getSleep: parameters date and callback must be specified!"

        @makeRequest "user/-/sleep/date/#{date}.json", (err, result) =>
            if err?
                logger.error "Fitbit.getSleep", date, err
            else
                logger.debug "Fitbit.getSleep", date, result
            callback err, result

    # Get activity data (steps, calories, etc) for the specified date.
    getActivities: (date, callback) =>
        if not date? or not callback?
            throw "Fitbit.getSteps: parameters date and callback must be specified!"

        @makeRequest "user/-/activities/date/#{date}.json", (err, result) =>
            if err?
                logger.error "Fitbit.getSteps", date, err
            else
                logger.debug "Fitbit.getSteps", date, result
            callback err, result

    # POST DATA
    # -------------------------------------------------------------------------

    # Post an activity to Fitbit.
    postActivity: (activity, callback) =>
        console.warn activity

    # PAGES
    # -------------------------------------------------------------------------

    # Get the Fitbit dashboard data.
    getDashboard: (callback) =>
        yesterday = moment().subtract("d", 1).format "YYYY-MM-DD"
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