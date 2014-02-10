# TOSHL API
# -----------------------------------------------------------------------------
# Module to read and add finance data to Toshl.
# More info at www.toshl.com.
class Toshl extends (require "./baseApi.coffee")

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
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
        @baseStart()

    # Stop the Toshl module.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Authentication helper for Toshl.
    auth: (req, res) =>
        security.processAuthToken "toshl", req, res

    # Make a request to the Toshl API.
    apiRequest: (path, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get data from the security module and set request URL.
        authCache = security.authCache["toshl"]
        reqUrl = settings.toshl.api.url + path
        reqUrl += "?" + params if params?

        logger.debug "Toshl.apiRequest", reqUrl

        # Make request using OAuth.
        authCache.oauth.get reqUrl, authCache.data.token, authCache.data.tokenSecret, callback

    # GET DATA
    # -------------------------------------------------------------------------

    # Get expenses with the specified filters.
    getExpenses: (filter, callback) =>
        logger.debug "Toshl.getExpenses", filter

    # PAGES
    # -------------------------------------------------------------------------

    # Get the Toshl dashboard data.
    getDashboard: (callback) =>
        @getExpenses()


# Singleton implementation.
# -----------------------------------------------------------------------------
Toshl.getInstance = ->
    @instance = new Toshl() if not @instance?
    return @instance

module.exports = exports = Toshl.getInstance()