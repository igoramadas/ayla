# NINJA BLOCKS API
# -----------------------------------------------------------------------------
# Module to collect and send data to devices connected to a Ninja Block.
# More info at http://docs.ninja.is.
class Ninja extends (require "./baseapi.coffee")

    expresser = require "expresser"

    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    ninjablocks = require "ninja-blocks"
    settings = expresser.settings

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
            @baseStart()

            events.on "Ninja.actuate433", @actuate433

            @ninjaApi = ninjablocks.app {user_access_token: settings.ninja.api.userToken}

            @getDevices()

    # Stop collecting data from Ninja Blocks.
    stop: =>
        @baseStop()

        events.off "Ninja.actuate433", @actuate433

    # GET DEVICE DATA
    # -------------------------------------------------------------------------

    # Gets the list of registered devices with Ninja Blocks.
    getDevices: (callback) =>
        hasCallback = lodash.isFunction callback

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

            # Callback set?
            callback err, result if hasCallback

    # SET DEVICE DATA
    # -------------------------------------------------------------------------

    # This should be called whenever new weather related data is downloaded
    # from the Ninja block. Consider the data as "current" if it was taken
    # less than 2 hours ago.
    setCurrentWeather: (devices) =>
        maxAge = moment().subtract(2, "h").unix()

        # Filter temperature and humidity devices.
        tempDevices = lodash.filter devices, {device_type: "temperature"}
        humiDevices = lodash.filter devices, {device_type: "humidity"}
        weather = {temperature: [], humidity: []}

        # Iterate all temperature devices and get recent data.
        for t in tempDevices
            if t.last_data?.timestamp > maxAge
                weather.temperature.push {shortName: t.shortName, value: t.last_data.DA, timestamp: t.last_data.timestamp}

        # Iterate all humidity devices and get recent data.
        for t in humiDevices
            if t.last_data?.timestamp > maxAge
                weather.humidity.push {shortName: t.shortName, value: t.last_data.DA, timestamp: t.last_data.timestamp}

        @setData "weather", weather

    # Helper to set the main RF 433 device.
    setRf433: (devices) =>
        guid = lodash.findKey devices, {device_type: "rf433"}

        if guid?
            @setData "rf433", {guid: guid, device: devices[guid]}

    # RF 433 SOCKETS
    # -------------------------------------------------------------------------

    # Actuate remote controlled RF433 actuators.The filter can be the subdevice ID,
    # short name defined or explicit filter.
    actuate433: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback
        rf433data = @data.rf433?[0].value

        if not @isRunning [@ninjaApi]
            callback "Ninja API client not running. Please check Ninja API settings." if hasCallback
            return
        else if not rf433data?
            callback "Ninja.actuate433", "RF 433 device not found." if hasCallback
            return

        subDevices = rf433data.device.subDevices
        actuators = []

        if lodash.isString filter or lodash.isNumber filter
            if subDevices[filter]?
                actuators = [subDevices[filter]]

        # Get correct list of subdevices based on the provided filter.
        if actuators.length < 1
            for id, device of subDevices
                if device.shortName is filter or device.shortName is filter.shortName or id is filter or id is filter.code
                    actuators.push device

        actuatorNames = lodash.pluck actuators, "shortName"
        logger.info "Ninja.actuate433", actuatorNames

        # Iterate and send command to subdevices twice to make sure it'll work.
        for a in actuators
            do (a) =>
                actuate = => @ninjaApi.device(rf433data.guid).actuate a.data
                setTimeout actuate, 1
                setTimeout actuate, 300

# Singleton implementation.
# -----------------------------------------------------------------------------
Ninja.getInstance = ->
    @instance = new Ninja() if not @instance?
    return @instance

module.exports = exports = Ninja.getInstance()
