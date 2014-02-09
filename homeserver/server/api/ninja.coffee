# NINJA BLOCKS API
# -----------------------------------------------------------------------------
class Ninja extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    ninjablocks = require "ninja-blocks"
    security = require "../security.coffee"

    # Cached Ninja api and RF433 objects.
    ninjaApi: null
    rf433: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Ninja module.
    init: =>
        @baseInit()

    # Start collecting data from Ninja Blocks.
    start: =>
        if settings.ninja?.api?
            @ninjaApi = ninjablocks.app {user_access_token: settings.ninja.api.userToken}

        @getDeviceList()
        @baseStart()

    # Stop collecting data from Ninja Blocks.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # -------------------------------------------------------------------------

    # This should be called whenever new weather related data is downloaded
    # from the Ninja block. If no `devices` are passed, use the default from data.
    # Consider the data as "current" if it was taken less than 2 hours ago.
    setCurrentWeather: =>
        devices = @data.devices
        maxAge = moment().subtract("h", 2).unix()

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

    # Helper to set the main RF 433 device.
    setRf433: (force) =>
        devices = @data.devices

        if not @data.rf433 or force
            guid = lodash.findKey devices, {device_type: "rf433"}
            if guid?
                @data.rf433 = {guid: guid, device: devices[guid]}
                logger.info "Ninja.setRf433", "Detected #{lodash.size devices[guid].subDevices} subdevices"

    # Gets the list of registered devices with Ninja Blocks.
    getDeviceList: (callback) =>
        if not @ninjaApi?
            logger.warn "Ninja.getDeviceList", "Ninja API not set (probably missing settings). Abort!"
            return
        else
            logger.debug "Ninja.getDeviceList"

        # Get all devices from Ninja Blocks.
        @ninjaApi.devices (err, result) =>
            if err?
                @logError "getDeviceList", err
            else
                @setData "devices", result

                # Set current weather and RF 433 device.
                @setCurrentWeather()
                @setRf433()

                logger.info "Ninja.getDeviceList", "Updated, #{lodash.size result} devices."

            # Callback set?
            callback err, result if callback?

    # RF 433 SOCKETS
    # -------------------------------------------------------------------------

    # Actuate remote controlled RF433 sockets.The filter can be the subdevice ID,
    # short name defined or explicit filter.
    actuate433: (filter) =>
        if not @ninjaApi?
            logger.warn "Ninja.actuate433", "Ninja API not set (probably missing settings). Abort!"
            return

        # Make sure RF 433 is set and working.
        if not @data.rf433?
            logger.warn "Ninja.actuate433", "RF 433 device is not set. Abort!"
            return

        actuators = @data.rf433.device.subDevices

        # Get correct list of subdevices based on the provided filter.
        if lodash.isString filter or lodash.isNumber filter
            if actuators[filter]?
                sockets = [actuators[filter]]
            else
                sockets = lodash.filter actuators, {shortName: filter}
        else
            sockets = lodash.filter actuators, filter

        # Log.
        logger.info "Ninja.actuate433", lodash.pluck sockets, "shortName"

        # Iterate and send command to subdevices.
        for s in sockets
            @ninjaApi.device(@data.rf433.device.guid).actuate s.data

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