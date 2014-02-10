# UBI API
# -----------------------------------------------------------------------------
# Module to collect data from Ubi sensors and send Ubi commands.
# More info at www.theubi.com.
class Ubi extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Ubi module.
    init: =>
        @baseInit()

    # Start collecting data from The Ubi.
    start: =>
        @baseStart()

    # Stop collecting data from The Ubi.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # ------------------------------------------------------------------------

    # Gets the list of registered devices with The Ubi.
    getDeviceData: (callback) =>
        console.warn 1


# Singleton implementation.
# -----------------------------------------------------------------------------
Ubi.getInstance = ->
    @instance = new Ubi() if not @instance?
    return @instance

module.exports = exports = Ubi.getInstance()