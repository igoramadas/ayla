# NINJA BLOCKS API
# -----------------------------------------------------------------------------
class Ninja extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    https = require "https"
    lodash = require "lodash"
    moment = require "moment"
    ninjablocks = require "ninja-blocks"
    querystring = require "querystring"
    security = require "../security.coffee"

    # Cached Ninja api and RF433 objects.
    ninjaApi: null
    rf433: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the GitHub module.
    init: =>
        @ninjaApi = ninjablocks.app {user_access_token: settings.ninja.api.userToken}
        @baseInit()


    # Start collecting weather data.
    start: =>
        @getDeviceList()
        @baseStart()

    # Stop collecting weather data.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # -------------------------------------------------------------------------

    # This should be called whenever new weather related data is downloaded
    # from the Ninja block.
    setCurrentWeather: =>
        maxAge = moment().subtract("m", settings.general.currentDataMaxAgeMinutes).unix()
        tempDevices = lodash.filter @data.devices, {device_type: "temperature"}
        humiDevices = lodash.filter @data.devices, {device_type: "humidity"}
        weather = {temperature: [], humidity: []}

        # Iterate all temperature devices and get recent data.
        for t in tempDevices
            if t.last_data?.timestamp > maxAge
                weather.temperature.push {shortName: t.shortName, value: t.last_data.DA}

        # Iterate all humidity devices and get recent data.
        for t in humiDevices
            if t.last_data?.timestamp > maxAge
                weather.humidity.push {shortName: t.shortName, value: t.last_data.DA}

        @setData "weather", weather

    # Gets the list of registered devices with Ninja Blocks.
    getDeviceList: (callback) =>
        logger.debug "Ninja.getDeviceList"

        @ninjaApi.devices (err, result) =>
            if err?
                @logError "getDeviceList", err
            else
                @setData "devices", result
                @setCurrentWeather()
                @rf433 = lodash.find result, {device_type: "rf433"} if not @rf433?
                @rf433Id = lodash.findKey result, {device_type: "rf433"}

            # Callback set?
            callback err, result if callback?

    # RF 433 SOCKETS
    # -------------------------------------------------------------------------

    # Actuate remote controlled RF433 sockets.The id can be the subdevice ID or the
    # short name defined on Ninja Blocks.
    actuate433: (id) =>
        if @rf433.subDevices[id]?
            sockets = [@rf433.subDevices[id]]
        else
            sockets = lodash.filter @rf433.subDevices, {shortName: id}

        logger.debug "Ninja.actuate433", id, sockets

        # Iterate and send command to subdevices.
        for s in sockets
            @ninjaApi.device(@rf433Id).actuate s.data

    # PAGES
    # -------------------------------------------------------------------------

    # Get the Fitbit dashboard data.
    getDashboard: (callback) =>
        @getDeviceList()


# Singleton implementation.
# -----------------------------------------------------------------------------
Ninja.getInstance = ->
    @instance = new Ninja() if not @instance?
    return @instance

module.exports = exports = Ninja.getInstance()