# NETWORK API
# -----------------------------------------------------------------------------
class Network

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    http = require "http"
    lodash = require "lodash"
    moment = require "moment"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Is it running on the expected local network, or remotely?
    isLocal: false

    # INIT
    # -------------------------------------------------------------------------

    # Init the Network module.
    init: =>
        @checkIP()

    # GET NETWORK STATS
    # -------------------------------------------------------------------------

    # Check if server is on same network as the Hue.
    checkIP: =>
        ips = utils.getServerIP()

        if ips.indexOf(settings.general.expectedLocalIP) < 0
            @isLocal = false
        else
            @isLocal = true

        logger.info "Network.checkIP", ips.join ", "


# Singleton implementation.
# -----------------------------------------------------------------------------
Network.getInstance = ->
    @instance = new Network() if not @instance?
    return @instance

module.exports = exports = Network.getInstance()