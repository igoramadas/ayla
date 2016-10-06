# ELECTRIC IMP API
# -----------------------------------------------------------------------------
# Module for Electric Imp devices. Compatible with the Hannah Dev Board
# running the agent and device code located under the /imp folder.
# More info at http://electricimp.com.
class ElectricImp extends (require "./baseapi.coffee")

    expresser = require "expresser"

    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings

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
            @getDeviceData()

    # Stop collecting Electric Imp data.
    stop: =>
        @baseStop()

    # DEVICE DATA
    # -------------------------------------------------------------------------

    # Get sensors data from the specified Electric Imp device. If no `deviceIds` is set
    # with filter then get data for all registered devices.
    getDeviceData: (filter, callback) =>
        if lodash.isFunction filter
            callback = filter
            filter = null
        else
            filter = @getJobArgs filter

        hasCallback = lodash.isFunction callback

        if not @isRunning [settings.electricimp.devices]
            callback "Module not running or devices not set. Please check the Electric Imp settings." if hasCallback
            return

        # Properly parse device ids (all devices, multiple devices if array, single device if string).
        if lodash.isArray filter
            deviceIds = filter
        else if lodash.isString filter
            deviceIds = [filter]
        else if filter?.deviceIds?
            deviceIds = filter.deviceIds
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

# Singleton implementation.
# -----------------------------------------------------------------------------
ElectricImp.getInstance = ->
    @instance = new ElectricImp() if not @instance?
    return @instance

module.exports = exports = ElectricImp.getInstance()
