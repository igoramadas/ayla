# NINJA BLOCKS API
# -----------------------------------------------------------------------------
# Module for Ninja Blocks and its connected devices.
# More info at http://docs.ninja.is
class Ninja extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    ninjablocks = require "ninja-blocks"

    # Cached Ninja api and RF433 objects.
    ninjaApi: null
    rf433: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Ninja Blocks module.
    init: =>
        @baseInit()

    # Start collecting data from Ninja Blocks.
    start: =>
        if not settings.ninja?.api?.userToken?
            @logError "Ninja.start", "Ninja API userToken not set."
        else
            @ninjaApi = ninjablocks.app {user_access_token: settings.ninja.api.userToken}
            @baseStart()

            if settings.modules.getDataOnStart
                @getDevices()

    # Stop collecting data from Ninja Blocks.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # -------------------------------------------------------------------------

    # Gets the list of registered devices with Ninja Blocks.
    getDevices: (callback) =>
        if not @ninjaApi?
            logger.warn "Ninja.getDevices", "Ninja API client not started (probably missing settings). Abort!"
            return

        # Get all devices from Ninja Blocks.
        @ninjaApi.devices (err, result) =>
            if err?
                @logError "getDevices", err
            else
                @setData "devices", result

                # Set current weather and RF 433 device status.
                @setCurrentWeather result
                @setRf433 result

                logger.info "Ninja.getDevices", "Got #{lodash.size result} devices."

            # Callback set?
            callback err, result if lodash.isFunction callback

    # SET DEVICE DATA
    # -------------------------------------------------------------------------

    # This should be called whenever new weather related data is downloaded
    # from the Ninja block. Consider the data as "current" if it was taken
    # less than 2 hours ago.
    setCurrentWeather: (devices) =>
        maxAge = moment().subtract("h", 2).unix()

        # Filter temperature and humidity devices.
        tempDevices = lodash.filter devices, {device_type: "temperature"}
        humiDevices = lodash.filter devices, {device_type: "humidity"}
        weather = {temperature: [], humidity: []}

        # Iterate all temperature devices and get recent data.
        for t in tempDevices
            if t.last_data?.timestamp > maxAge
                weather.temperature.push {shortName: t.shortName, value: t.last_data.D, timestamp: t.last_data.timestamp}

        # Iterate all humidity devices and get recent data.
        for t in humiDevices
            if t.last_data?.timestamp > maxAge
                weather.humidity.push {shortName: t.shortName, value: t.last_data.DA, timestamp: t.last_data.timestamp}

        @setData "weather", weather
        logger.info "Ninja.setCurrentWeather", weather

    # Helper to set the main RF 433 device.
    setRf433: (devices) =>
        guid = lodash.findKey devices, {device_type: "rf433"}

        if guid?
            @rf433 = {guid: guid, device: devices[guid]}
            logger.debug "Ninja.setRf433", "Detected #{lodash.size devices[guid].subDevices} subdevices."

    # RF 433 SOCKETS
    # -------------------------------------------------------------------------

    # Actuate remote controlled RF433 sockets.The filter can be the subdevice ID,
    # short name defined or explicit filter.
    actuate433: (filter, callback) =>
        if not @isRunning [@ninjaApi]
            callback "Ninja API client not running. Please check Ninja API settings." if callback?
            return
        else if not @rf433?
            callback "Ninja.actuate433", "RF 433 device not found." if callback?
            return

        subdevices = @rf433.device.subDevices

        # Get correct list of subdevices based on the provided filter.
        if lodash.isString filter or lodash.isNumber filter
            if subdevices[filter]?
                sockets = [subdevices[filter]]
            else
                sockets = lodash.filter subdevices, {shortName: filter}
        else
            sockets = lodash.filter subdevices, filter

        socketNames = lodash.pluck sockets, "shortName"
        logger.info "Ninja.actuate433", socketNames

        # Iterate and send command to subdevices.
        for s in sockets
            @ninjaApi.device(@rf433.device.guid).actuate s.data


# Singleton implementation.
# -----------------------------------------------------------------------------
Ninja.getInstance = ->
    @instance = new Ninja() if not @instance?
    return @instance

module.exports = exports = Ninja.getInstance()