# ELECTRIC IMP API
# -----------------------------------------------------------------------------
# Module for Electric Imp devices (http://electricimp.com).
# Compatible with the Hannah Dev Board running the agent and device code
# located under the /imp folder.
class ElectricImp extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Electric Imp module.
    init: =>
        @baseInit()

    # Start collecting Electric Imp data.
    start: =>
        @getDeviceData()
        @baseStart()

    # Stop collecting Electric Imp data.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # -------------------------------------------------------------------------

    # Get sensors data from the specified Electric Imp device. If no `deviceIds` is set
    # then get data for all registered devices.
    getDeviceData: (deviceIds) =>
        return @notRunning "getDeviceData" if not @running?

        # Properly parse device ids (all devices, multiple devices if array, single device if string).
        deviceIds = settings.electricImp.devices if not deviceIds?
        deviceIds = [deviceIds] if not lodash.isArray deviceIds

        # For each device make a request and save resulting data.
        for id in ids
            do (id) =>
                @makeRequest settings.electricImp.agentUrl + id, (err, result) =>
                    if err?
                        @logError "ElectricImp.getDeviceData", id, err
                    else
                        # If the imp code has no id, set the same as the device.
                        result.id = id if not result.id?
                        @setData result.id, result

    # JOBS
    # -------------------------------------------------------------------------

    # Refresh Electric Imp data every 2 minutes.
    jobGetDeviceData: =>
        @getDeviceData()


# Singleton implementation.
# -----------------------------------------------------------------------------
ElectricImp.getInstance = ->
    @instance = new ElectricImp() if not @instance?
    return @instance

module.exports = exports = ElectricImp.getInstance()