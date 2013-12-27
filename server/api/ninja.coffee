# NINJA BLOCKS API
# -----------------------------------------------------------------------------
class Ninja

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    https = require "https"
    lodash = require "lodash"
    moment = require "moment"
    ninjablocks = require "ninja-blocks"
    querystring = require "querystring"
    security = require "../security.coffee"

    # Create Ninja App.
    ninjaApp: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Ninja Blocks module.
    init: =>
        @ninjaApp = ninjablocks.app {user_access_token: settings.ninja.appSecret}

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Authentication helper for Ninja Blocks.
    auth: (req, res) =>
        security.processAuthToken "fitbit", req, res

    # Make a request to the Ninja Blocks API.
    makeRequest: (path, params, callback) =>
        reqHasError = false

        # Make the HTTP request to the Ninja API.
        reqUrl = settings.ninja.apiUrl + path + "/" + params + "?user_access_token=" + settings.ninja.accessToken
        req = https.get reqUrl, (response) ->
            response.downloadedData = ""
            response.addListener "data", (data) -> response.downloadedData += data
            response.addListener "end", -> callback null, JSON.parse response.downloadedData if not reqHasError

        # On request error, trigger the callback straight away.
        req.on "error", (err) ->
            reqHasError = true
            callback err

    # GET DATA
    # -------------------------------------------------------------------------

    # Get data for the specified device ID.
    getDeviceData: (deviceId, callback) =>
        if not deviceId? or not callback?
            throw "Ninja.getDeviceData: parameters deviceId and callback must be specified!"

        @makeRequest "device", deviceId, (err, result) =>
            if err?
                logger.error "Ninja.getDeviceData", deviceId, err
            else
                logger.debug "Ninja.getDeviceData", deviceId, result
            callback err, result

    # PAGES
    # -------------------------------------------------------------------------

    # Get the Fitbit dashboard data.
    getDashboard: (callback) =>
        @getDeviceData "1313BB000456_0404_0_31", callback


# Singleton implementation.
# -----------------------------------------------------------------------------
Ninja.getInstance = ->
    @instance = new Ninja() if not @instance?
    return @instance

module.exports = exports = Ninja.getInstance()