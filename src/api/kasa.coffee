# TP-LINK KASA API
# -----------------------------------------------------------------------------
# Module to identify and control Kasa devices.
class Kasa extends (require "./baseapi.coffee")

    expresser = require "expresser"
    async = expresser.libs.async
    datastore = expresser.datastore
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    appData = require "../appdata.coffee"
    client = require("tplink-smarthome-api").Client
    url = require "url"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Kasa module and schedule a job to refresh status every few seconds.
    init: =>
        @baseInit()

    # Start the module and refresh the device data.
    start: =>
        @baseStart()

        events.on "Kasa.switchDevice", @switchDevice

        @refreshDevices()

    # Stop the module and cancel the refresh jobs.
    stop: =>
        @baseStop()

        events.off "Kasa.switchDevice", @switchDevice

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Kasa API.
    apiRequest: (urlPath, params, callback) =>
        logger.debug "NOT READY"

    # KASA METHODS
    # -------------------------------------------------------------------------

    # Refresh information from the Kasa API.
    refreshDevices: (callback) =>
        logger.debug "NOT READY"

    # Turn group lights on (true) or off (false). If no ID is passed or ID is 0, switch all lights.
    switchDevice: (id, turnOn, callback) =>
        logger.debug "NOT READY"

# Singleton implementation.
# -----------------------------------------------------------------------------
Kasa.getInstance = ->
    @instance = new Kasa() if not @instance?
    return @instance

module.exports = exports = Kasa.getInstance()
