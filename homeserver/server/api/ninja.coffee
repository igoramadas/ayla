# NINJA BLOCKS API
# -----------------------------------------------------------------------------
class Ninja extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    lodash = require "lodash"
    moment = require "moment"
    ninjablocks = require "ninja-blocks"
    security = require "../security.coffee"

    # Cached Ninja api and RF433 objects.
    ninjaApi: null
    rf433: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Ninja module.
    init: =>
        if not settings.ninja?.api?
            logger.warn "Ninja.init", "Ninja API settings are not defined!"
            return

        @ninjaApi = ninjablocks.app {user_access_token: settings.ninja.api.userToken}
        @baseInit()

    # Start collecting data from Ninja Blocks.
    start: =>
        @getDeviceList()
        @baseStart()

    # Stop collecting data from Ninja Blocks.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # -------------------------------------------------------------------------

    # This should be called whenever new weather related data is downloaded
    # from the Ninja block. If no `devices` are passed, use the default from data.
    setCurrentWeather: (devices) =>
        devices = @data.devices if not devices?
        maxAge = moment().subtract("m", settings.general.currentDataMaxAgeMinutes).unix()

        # Filter temperature and humidity devices.
        tempDevices = lodash.filter devices, {device_type: "temperature"}
        humiDevices = lodash.filter devices, {device_type: "humidity"}
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
        if not @ninjaApi?
            logger.warn "Ninja.getDeviceList", "Ninja API object was not created. Abort!"
            return
        else
            logger.debug "Ninja.getDeviceList"

        @ninjaApi.devices (err, result) =>
            if err?
                @logError "getDeviceList", err
            else
                @setData "devices", result
                @setCurrentWeather()
                @rf433 = lodash.find result, {device_type: "rf433"} if not @rf433?
                @rf433Id = lodash.findKey result, {device_type: "rf433"}

                logger.info "Ninja.getDeviceList", "#{result.length} devices updated."

            # Callback set?
            callback err, result if callback?

    # RF 433 SOCKETS
    # -------------------------------------------------------------------------

    # Actuate remote controlled RF433 sockets.The filter can be the subdevice ID,
    # short name defined or explicit filter.
    actuate433: (filter) =>
        if not @ninjaApi?
            logger.warn "Ninja.actuate433", "Ninja API object was not created. Abort!"
            return

        # Get correct list of subdevices based on the provided filter.
        if lodash.isString filter or lodash.isNumber filter
            if @rf433.subDevices[filter]?
                sockets = [@rf433.subDevices[filter]]
            else
                sockets = lodash.filter @rf433.subDevices, {shortName: filter}
        else
            sockets = lodash.filter @rf433.subDevices, filter

        # Log.
        logger.info "Ninja.actuate433", lodash.pluck sockets, "shortName"

        # Iterate and send command to subdevices.
        for s in sockets
            @ninjaApi.device(@rf433Id).actuate s.data

    # JOBS
    # -------------------------------------------------------------------------

    # Refresh ninja device details every hour.
    jobGetDeviceList: =>
        @getDeviceList()

    # PAGES
    # -------------------------------------------------------------------------

    # Get the Ninja Blocks dashboard data.
    getDashboard: (callback) =>
        @getDeviceList()


# Singleton implementation.
# -----------------------------------------------------------------------------
Ninja.getInstance = ->
    @instance = new Ninja() if not @instance?
    return @instance

module.exports = exports = Ninja.getInstance()