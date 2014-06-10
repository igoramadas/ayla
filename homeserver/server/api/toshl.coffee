# TOSHL API
# -----------------------------------------------------------------------------
# Module to read and add finance data to Toshl.
# More info at https://developer.toshl.com
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
            if err?
                @logError "Toshl.start", err
            else
                @baseStart()

                if settings.modules.getDataOnStart and result.length > 0
                    @getRecentExpenses()

        @baseStart()

    # Stop the Toshl module.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Toshl API.
    apiRequest: (path, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth]
            callback "Module not running or OAuth client not ready. Please check Toshl API settings." if callback?
            return

        # Get data from the security module and set request URL.
        reqUrl = settings.toshl.api.url + path
        reqUrl += "?" + querystring.stringify params if params?

        logger.debug "Toshl.apiRequest", reqUrl

        # Make request using OAuth.
        @oauth.get reqUrl, (err, result) =>
            result = JSON.parse result if lodash.isString result
            callback err, result if lodash.isFunction callback

    # GET EXPENSES
    # -------------------------------------------------------------------------

    # Get expenses with the specified filter. Filter can have the following
    # properties: from, to, tags, per_page, page.
    getExpenses: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null

        params = filter or {}

        @apiRequest "expenses", params, (err, result) =>
            if err?
                @logError "Toshl.getExpenses", err
            else
                @setData "expenses", result, filter

            callback err, result if lodash.isFunction callback

    # Get recent expenses from Toshl for the past days depending on the
    # defined `recentExpenseDays` setting.
    getRecentExpenses: (callback) =>
        from = moment().subtract("d", settings.toshl.recentExpensesDays).format settings.toshl.dateFormat
        to = moment().format settings.toshl.dateFormat

        @getExpenses {from: from, to: to}, callback


# Singleton implementation.
# -----------------------------------------------------------------------------
Toshl.getInstance = ->
    @instance = new Toshl() if not @instance?
    return @instance

module.exports = exports = Toshl.getInstance()