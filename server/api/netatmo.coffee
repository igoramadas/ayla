# NETATMO API
# -----------------------------------------------------------------------------
# Collect weather and climate data from Netatmo devices. Supports indoor and
# outdoor modules, the rain gauge and Welcome cameras.
# More info at http://dev.netatmo.com.
class Netatmo extends (require "./baseapi.coffee")

    expresser = require "expresser"

    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings

    querystring = require "querystring"

    # INIT
    # -------------------------------------------------------------------------

    # Netatmo init.
    init: ->
        @baseInit()

    # Start collecting weather data.
    start: =>
        @baseStart()

        @oauthInit (err, result) =>
            if err?
                @logError "Netatmo.start", err

        events.on "Netatmo.getWeather", @getWeather
        events.on "Netatmo.getWelcome", @getWelcome

    # Stop collecting weather data.
    stop: =>
        @baseStop()

        events.off "Netatmo.getWeather", @getWeather
        events.off "Netatmo.getWelcome", @getWelcome

    # Load initial data, usually called when module has authenticated.
    getInitialData: =>
        return if @initialDataLoaded

        @initialDataLoaded = true

        # Get device list first, then get indoor and outdoor readings.
        @getWeather()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Helper to get a formatted result.
    getResultBody = (result, params) ->
        arr = []
        types = params.type.split ","

        # Iterate result body and create the formatted object.
        for key, value of result.body
            body = {timestamp: key}
            i = 0

            # Iterate each type to set formatted value.
            for t in types
                body[t.toLowerCase()] = value[i] if value[i]?
                i++

            # Push to the final array.
            arr.push body

        # Return formatted array.
        return arr

    # Make a request to the Netatmo API.
    apiRequest: (path, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth.authenticated]
            callback "Module not running or OAuth client not ready. Please check Netatmo API settings."
            return

        # Set default parameters and request URL.
        reqUrl = settings.netatmo.api.url + path + "?"
        params = {} if not params?

        # Add parameters to request URL.
        reqUrl += querystring.stringify params

        logger.debug "Netatmo.apiRequest", reqUrl

        # Make request using OAuth.
        @oauth.get reqUrl, (err, result) =>
            result = JSON.parse result if result? and lodash.isString result
            callback err, result

    # WEATHER DATA
    # -------------------------------------------------------------------------

    # Get weather data from Netatmo stations.
    getWeather: (callback) =>
        hasCallback = lodash.isFunction callback

        @apiRequest "getstationsdata", (err, result) =>
            if err?
                @logError "Netatmo.getWeather", err
            else
                deviceData = result.body.devices
                @setData "weather", deviceData

            callback err, result if hasCallback

    # WELCOME CAMERA DATA
    # -------------------------------------------------------------------------

    # Get home data from Welcome cameras.
    getWelcome: (callback) =>
        hasCallback = lodash.isFunction callback

        @apiRequest "gethomedata", (err, result) =>
            if err?
                @logError "Netatmo.getWelcome", err
            else
                homes = result.body.homes
                @setData "welcome", homes

            callback err, result if hasCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
Netatmo.getInstance = ->
    @instance = new Netatmo() if not @instance?
    return @instance

module.exports = exports = Netatmo.getInstance()
