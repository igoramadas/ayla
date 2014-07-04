# GARMIN API
# NOT READY YET!!!
# -----------------------------------------------------------------------------
# Module to collect data from Garmin.
class Garmin extends (require "./baseapi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Garmin module.
    init: =>
        @baseInit()

    # Start collecting data from Garmin Connect.
    start: =>
        @baseStart()

    # Stop collecting data from Garmin Connect.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # ------------------------------------------------------------------------

    # Gets the list of registered devices with Garmin.
    getDeviceData: (callback) =>
        console.warn 1


# Singleton implementation.
# -----------------------------------------------------------------------------
Garmin.getInstance = ->
    @instance = new Garmin() if not @instance?
    return @instance

module.exports = exports = Garmin.getInstance()