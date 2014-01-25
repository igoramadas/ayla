# ELECTRIC IMP API
# -----------------------------------------------------------------------------
class ElectricImp extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    lodash = require "lodash"
    moment = require "moment"

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

    # Gets the data.
    getDeviceData: =>
        @makeRequest settings.electricImp.api.url, (err, result) =>
            if err?
                @logError "ElectricImp.getDeviceData", err
            else
                @setData "current", result

    # JOBS
    # -------------------------------------------------------------------------

    # Refresh weather data and save to the database.
    jobGetWeather: =>
        @getCurrentWeather()


# Singleton implementation.
# -----------------------------------------------------------------------------
ElectricImp.getInstance = ->
    @instance = new ElectricImp() if not @instance?
    return @instance

module.exports = exports = ElectricImp.getInstance()