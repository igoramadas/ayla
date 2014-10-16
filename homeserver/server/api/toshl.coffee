# TOSHL API
# -----------------------------------------------------------------------------
# Module to read and add finances and budget data to Toshl.
# More info at https://developer.toshl.com.
class Toshl extends (require "./baseapi.coffee")

    expresser = require "expresser"

    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    querystring = require "querystring"
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the Toshl module.
    init: =>
        @baseInit()

    # Start the Toshl module.
    start: =>
        @baseStart()

        @oauthInit (err, result) =>
            if err?
                @logError "Toshl.start", err

    # Stop the Toshl module.
    stop: =>
        @baseStop()

    # Load initial data, usually called when module has authenticated.
    getInitialData: =>
        return if @initialDataLoaded

        @initialDataLoaded = true

        @getMonths()
        @getRecentExpenses()
        @getRecentIncomes()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Toshl API.
    apiRequest: (urlpath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth.authenticated]
            callback "Module not running or OAuth client not ready. Please check Toshl API settings."
            return

        # Get data from the security module and set request URL.
        reqUrl = settings.toshl.api.url + urlpath
        reqUrl += "?" + querystring.stringify params if params?

        logger.debug "Toshl.apiRequest", reqUrl

        # Make request using OAuth.
        @oauth.get reqUrl, (err, result) =>
            result = JSON.parse result if lodash.isString result
            callback err, result

    # GET MONTHS
    # -------------------------------------------------------------------------

    # Get overview expenses and incomes for the specified month. If no month is
    # set then return everything.
    getMonths: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback

        filter = {} if not filter?

        # If date is set then use the corresponding URL path.
        if filter.year? and filter.month?
            urlpath = "months/#{filter.year}/#{filter.month}"
            delete filter.year
            delete filter.month
        else
            urlpath = "months"

        # Call Toshl API.
        @apiRequest urlpath, filter, (err, result) =>
            if err?
                @logError "Toshl.getMonths", err
            else
                @setData "months", result, filter

            callback err, result if hasCallback

    # GET EXPENSES
    # -------------------------------------------------------------------------

    # Get expenses with the specified filter. Filter can have the following
    # properties: from, to, tags, per_page, page.
    getExpenses: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback

        @apiRequest "expenses", filter, (err, result) =>
            if err?
                @logError "Toshl.getExpenses", err
            else
                @setData "expenses", result, filter

            callback err, result if hasCallback

    # Get recent expenses from Toshl for the past days depending on the
    # defined `recentDays` setting.
    getRecentExpenses: (callback) =>
        hasCallback = lodash.isFunction callback

        from = moment().subtract(settings.toshl.recentDays, "d").format settings.toshl.dateFormat
        to = moment().format settings.toshl.dateFormat
        filter = {from: from, to: to, per_page: 300}

        @getExpenses filter, (err, result) =>
            @setData "recentExpenses", result if result?
            callback err, result if hasCallback

    # GET INCOMES
    # -------------------------------------------------------------------------

    # Get incomes with the specified filter. Filter can have the following
    # properties: from, to, tags, per_page, page.
    getIncomes: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback

        @apiRequest "incomes", filter, (err, result) =>
            if err?
                @logError "Toshl.getIncomes", err
            else
                @setData "incomes", result, filter

            callback err, result if hasCallback

    # Get recent incomes from Toshl for the past days depending on the
    # defined `recentDays` setting.
    getRecentIncomes: (callback) =>
        hasCallback = lodash.isFunction callback

        from = moment().subtract(settings.toshl.recentDays, "d").format settings.toshl.dateFormat
        to = moment().format settings.toshl.dateFormat
        filter = {from: from, to: to, per_page: 300}

        @getIncomes filter, (err, result) =>
            @setData "recentIncomes", result if result?
            callback err, result if hasCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
Toshl.getInstance = ->
    @instance = new Toshl() if not @instance?
    return @instance

module.exports = exports = Toshl.getInstance()
