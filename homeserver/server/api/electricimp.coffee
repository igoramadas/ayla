# ELECTRIC IMP API
# -----------------------------------------------------------------------------
# Module for Electric Imp devices. Compatible with the Hannah Dev Board
# running the agent and device code located under the /imp folder.
# More info at http://electricimp.com
class ElectricImp extends (require "./baseapi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Electric Imp module.
    init: =>
        @baseInit()

    # Start collecting Electric Imp data.
    start: =>
        if not settings.electricimp?.devices?
            @logError "ElectricImp.start", "No Electric Imp devices defined. Please check the settings."
        else
            @baseStart()

            if settings.modules.getDataOnStart
                @getDeviceData()

    # Stop collecting Electric Imp data.
    stop: =>
        @baseStop()

    # DEVICE DATA
    # -------------------------------------------------------------------------

    # Get sensors data from the specified Electric Imp device. If no `deviceIds` is set
    # with options then get data for all registered devices.
    getDeviceData: (options, callback) =>
        if not callback? and lodash.isFunction options
            callback = options
            options = null

        if not @isRunning [settings.electricimp.devices]
            callback "Module not running or devices not set. Please check the Electric Imp settings." if callback?
            return

        # Properly parse device ids (all devices, multiple devices if array, single device if string).
        if lodash.isArray options
            deviceIds = options
        else if lodash.isString options
            deviceIds = [options]
        else if options?.deviceIds?
            deviceIds = options.deviceIds
        else
            deviceIds = settings.electricimp.devices

        # For each device make a request and save resulting data.
        for id in deviceIds
            do (id) =>
                @makeRequest settings.electricimp.agentUrl + id, (err, result) =>
                    if err?
                        @logError "ElectricImp.getDeviceData", id, err
                    else
                        # If the imp code has no id, set the same as the device.
                        result.id = id if not result.id?
                        @setData result.id, result
                        logger.info "ElectricImp.getDeviceData", id, result


# Singleton implementation.
# -----------------------------------------------------------------------------
ElectricImp.getInstance = ->
    @instance = new ElectricImp() if not @instance?
    return @instance

module.exports = exports = ElectricImp.getInstance()