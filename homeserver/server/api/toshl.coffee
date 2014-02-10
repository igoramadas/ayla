# TOSHL API
# -----------------------------------------------------------------------------
# Module to read and add finance data to Toshl.
# More info at www.toshl.com.
class Toshl extends (require "./baseApi.coffee")

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    querystring = require "querystring"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Toshl module.
    init: =>
        @baseInit()

    # Start the Toshl module.
    start: =>
        @oauthInit (err, result) =>
            if not err?
                @jobGetRecentExpenses()

        @baseStart()

    # Stop the Toshl module.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Toshl API.
    apiRequest: (path, params, callback) =>
        if not @oauth.client?
            callback "OAuth client is not ready. Please check Toshl API settings." if callback?
            return

        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get data from the security module and set request URL.
        reqUrl = settings.toshl.api.url + path
        reqUrl += "?" + querystring.stringify params if params?

        logger.debug "Toshl.apiRequest", reqUrl

        # Make request using OAuth.
        @oauth.get reqUrl, (err, result) =>
            if err?
                @logError "Toshl.apiRequest", path, params, err
            else
                logger.debug "Toshl.apiRequest", path, params, result

            result = JSON.parse result if lodash.isString result
            callback err, result if callback?

    # GET DATA
    # -------------------------------------------------------------------------

    # Get expenses with the specified filter. Filter can have the following
    # properties: from, to, tags, per_page, page.
    getExpenses: (filter, callback) =>
        params = filter or {}

        @apiRequest "expenses", params, (err, result) =>
            console.warn err, result

    # JOBS
    # -------------------------------------------------------------------------

    # Get recent expenses from Toshl.
    jobGetRecentExpenses: =>
        logger.info "Netatmo.getRecentExpenses"

        from = moment().subtract("d", settings.toshl.recentExpensesDays).format settings.toshl.dateFormat
        to = moment().format settings.toshl.dateFormat

        @getExpenses {from: from, to: to}


# Singleton implementation.
# -----------------------------------------------------------------------------
Toshl.getInstance = ->
    @instance = new Toshl() if not @instance?
    return @instance

module.exports = exports = Toshl.getInstance()