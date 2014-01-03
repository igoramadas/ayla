# NETWORK API
# -----------------------------------------------------------------------------
class Network extends (require "./apiBase.coffee")

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    data = require "../data.coffee"
    http = require "http"
    lodash = require "lodash"
    mdns = require "mdns"
    moment = require "moment"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all network status info.
    status: {}

    # Local network discovery / browser.
    browser: null

    # Is it running on the expected local network, or remotely?
    isHome: false

    # INIT
    # -------------------------------------------------------------------------

    # Init the Network module.
    init: =>
        @browser = mdns.createBrowser mdns.tcp("http")
        @browser.on "serviceUp", @onServiceUp
        @browser.on "serviceDown", @onServiceDown

        @checkIP()
        @baseInit()

    # Start monitoring the network.
    start: =>
        @baseStart()
        @browser.start()

    # Stop monitoring the network.
    stop: =>
        @baseStop()
        @browser.stop()

    # GET NETWORK STATS
    # -------------------------------------------------------------------------

    # Check if Ayla server is on the home network.
    checkIP: =>
        logger.debug "Network.checkIP", "Expected home IP: #{data.static.network.home.ip}"

        ips = utils.getServerIP()

        if ips.indexOf(data.static.network.home.ip) < 0
            @isHome = false
        else
            @isHome = true

        logger.info "Network.checkIP", ips, "isHome = #{@isHome}"

    # Check if the specified device / server / URL is up.
    checkDevice: (device, callback) =>
        if not device.addresses?
            device.addresses []
            device.addresses.push device.localIP

    # Probe the current network and check device statuses.
    probe: =>
        for nKey, nData of data.static.network
            @status[nKey] = nData if not @status[nKey]?

            # Iterate network devices.
            @checkDevice d for d in @status[nKey].devices

    # SERVICE DISCOVERY
    # -------------------------------------------------------------------------

    # When a new service is discovered on the network.
    onServiceUp: (service) =>
        logger.debug "Network.onServiceUp", service

        for key, data of @status
            existingDevice = lodash.find data.devices, (d) =>
                return service.addresses.indexOf d.localIP >= 0 and service.port is d.localPort

            # Create new device or update existing?
            if not existingDevice?
                logger.info "Network.onServiceUp", "New", service.name, service.addresses, service.port
                existingDevice = {id: device.name}
                isNew = true
            else
                logger.info "Network.onServiceUp", "Existing", service.name, service.addresses, service.port
                isNew = false

            # Set device properties.
            existingDevice.host = device.host
            existingDevice.addresses = device.addresses
            existingDevice.up = true

            @status[key].devices.push existingDevice if isNew

    # When a service disappears from the network.
    onServiceDown: (service) =>
        logger.info "Network.onServiceDown", service.name

        for key, data of @status
            existingDevice = lodash.find data.devices, (d) =>
                return service.addresses.indexOf d.localIP >= 0 and service.port is d.localPort

            if existingDevice?
                existingDevice.up = false

    # JOBS
    # -------------------------------------------------------------------------

    # Keep probing network.
    jobProbe: =>
        @probe()


# Singleton implementation.
# -----------------------------------------------------------------------------
Network.getInstance = ->
    @instance = new Network() if not @instance?
    return @instance

module.exports = exports = Network.getInstance()