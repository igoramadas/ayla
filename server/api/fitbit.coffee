# FITBIT
# -----------------------------------------------------------------------------
class Fitbit

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    lodash = require "lodash"
    querystring = require "querystring"
    security = require "../security.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Fitbit module.
    init: =>
        logger.debug "Fitbit.init"

    # AUTH AND BASE REQUEST
    # -------------------------------------------------------------------------

    # Authentication helper for Fitbit.
    auth: (req, res, callback) =>
        security.processAuthToken "fitbit", {version: "1.0"}, req, res, (err, result) =>
            console.warn err, result

    subscribe: =>
        postUrl = "#{settings.fitbit.apiUrl}user/-/apiSubscriptions/#{user.id}-all.json"

        # Subscribe this application to updates from the user's data
        oauth.post postUrl, token, tokenSecret, null, null, (err, data, res) ->
            if err?
                logger.error "Security.authFitbit", postUrl, err
            callback err, user

    makeRequest: (path, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        oauthCache = security.oauthCache["fitbit"]
        reqUrl = settings.fitbit.apiUrl + path

        if params?
            reqUrl += "?" + querystring.stringify params

        oauthCache.oauth.get reqUrl, oauthCache.token, oauthCache.tokenSecret, callback

    # SLEEP
    # -------------------------------------------------------------------------

    getSleepData: (date) =>
        @makeRequest "user/-/sleep/date/#{date}.json", (err, result) =>
            console.warn err, result

    # ACTIVITIES
    # -------------------------------------------------------------------------

    # Post an activity to Fitbit.
    postActivity: (activity) =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Fitbit.getInstance = ->
    @instance = new Fitbit() if not @instance?
    return @instance

module.exports = exports = Fitbit.getInstance()