# ELECTRIC IMP API
# -----------------------------------------------------------------------------
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

    # Gets sensors data from the Electric Imp device.
    getDeviceData: =>
        if not settings.electricImp?.api?
            logger.warn "ElectricImp.getDeviceData", "Electric Imp API settings are not defined. Abort!"
            return

        @makeRequest settings.electricImp.api.url, (err, result) =>
            if err?
                @logError "ElectricImp.getDeviceData", err
            else
                @setData "current", result

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