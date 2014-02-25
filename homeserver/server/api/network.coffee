# NETWORK API
# -----------------------------------------------------------------------------
# Module for internal network management and discovery. Please note that a few
# other API modules depend on this Network module to work, so unless you have a
# very specific use case please leave it on the `settings.modules.enabled` list.
class Network extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    buffer = require "buffer"
    dgram = require "dgram"
    fs = require "fs"
    http = require "http"
    lodash = expresser.libs.lodash
    mdns = require "mdns2"
    moment = expresser.libs.moment
    path = require "path"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Local network discovery.
    mdnsBrowser: null

    # Holds user status (online true, offline false) based on their mobile
    # phones connected to the same network.
    userStatus: {}

    # Is it running on the expected local network, or remotely?
    isHome: true

    # INIT
    # -------------------------------------------------------------------------

    # Init the Network module.
    init: =>
        @mdnsBrowser = mdns.createBrowser mdns.tcp("http")
        @checkIP()

        @baseInit {devices: []}

    # Start monitoring the network.
    start: =>
        @mdnsBrowser.on "serviceUp", @onServiceUp
        @mdnsBrowser.on "serviceDown", @onServiceDown
        @mdnsBrowser.start()

        @baseStart()

        if settings.modules.getDataOnStart
            @probeDevices()

    # Stop monitoring the network.
    stop: =>
        @mdnsBrowser.off "serviceUp", @onServiceUp
        @mdnsBrowser.off "serviceDown", @onServiceDown
        @mdnsBrowser.stop()

        @baseStop()

    # GET NETWORK STATS
    # -------------------------------------------------------------------------

    # Check if Ayla server is on the home network.
    checkIP: =>
        if not settings.network?.router?
            logger.warn "Network.checkIP", "Network router settings are not defined. Skip!"
            return
        else
            logger.debug "Network.checkIP", "Expected router IP: #{settings.network.router.ip}"

        # Get and process current IP.
        ips = utils.getServerIP()
        ips = ips.join ","
        homeSubnet = settings.network.router?.ip?.substring 0, 7

        if not homeSubnet? or ips.indexOf(homeSubnet) < 0
            @isHome = false
        else
            @isHome = true

        logger.info "Network.checkIP", ips, "isHome = #{@isHome}"

    # Check if the specified device / server / URL is up.
    checkDevice: (device) =>
        logger.debug "Network.checkDevice", device

        # Abort if device was found using mdns.
        return if device.mdns

        # Are addresses set?
        if not device.addresses?
            device.addresses = []
            device.addresses.push device.ip

        # Not checked yet? Set `up` to false.
        device.up = false if not device.up?

        # Try connecting and set device as online.
        req = http.get {host: device.ip, port: device.localPort}, (response) ->
            response.addListener "data", (data) -> response.isValid = true
            response.addListener "end", -> device.up = true if response.isValid

        # On request error, set device as offline.
        req.on "error", (err) -> device.up = false

    # Probe the current network and check device statuses.
    probeDevices: (callback) =>
        if not @isRunning [settings.network.devices]
            errMsg = "Module is not running or no devices are set. Please check the network devices list on settings."

            if lodash.isArray callback
                callback errMsg
            else
                logger.warn "Network.probeDevices", errMsg
            return

        @checkDevice d for d in settings.network.devices

    # NETWORK COMMANDS
    # -------------------------------------------------------------------------

    # Helper to create a WOL magic packet.
    wolMagicPacket = (mac) ->
        nmacs = 16
        mbytes = 6
        buf = new buffer.Buffer mbytes        

        # Parse and rewrite mac address.
        if mac.length is 2 * mbytes + (mbytes - 1)
            mac = mac.replace(new RegExp(mac[2], "g"), "")

        # Check if mac is valid.
        if mac.length isnt 2 * mbytes or mac.match(/[^a-fA-F0-9]/)
            throw new Error "MAC address #{mac} is not valid."

        i = 0
        while i < mbytes
            buf[i] = parseInt mac.substr(2 * i, 2), 16
            i++

        # Create result buffer.
        result = new buffer.Buffer (1 + nmacs) * mbytes

        i = 0
        while i < mbytes
            result[i] = 0xff
            i++

        i = 0
        while i < nmacs
            buf.copy result, (i + 1) * mbytes, 0, buf.length
            i++

        return result

    # Send a wake-on-lan packet to the specified device. Using ports 7 and 9.
    wol: (mac, ip, callback) =>
        if not callback? and lodash.isFunction ip
            callback = ip
            ip = "255.255.255.255"

        # The mac address is mandatory!
        if not mac?
            throw new Error "A valid MAC address must be specified."

        # Set default options (IP, number of packets, interval and port).
        numPackets = 3

        # Create magic packet and the socket connection.
        packet = wolMagicPacket mac
        socket = dgram.createSocket "udp4"
        wolTimer = null
        i = 0

        # Resulting variables.
        err = null
        result = null

        # Socket post write helper.
        postWrite = (err, result) ->
            if err? or i is (numPackets * 2)
                try
                    socket.close()
                    clearTimeout wolTimer if wolTimer?
                catch ex
                    err = ex
                callback err, result if lodash.isFunction callback


        # Socket send helper.
        sendWol = ->
            i += 1

            # Delay sending.
            socket.send packet, 0, packet.length, 7, ip, postWrite
            socket.send packet, 0, packet.length, 9, ip, postWrite

            if i < numPackets
                wolTimer = setTimeout sendWol, 300
            else
                wolTimer = null

        # Socket broadcast when listening.
        socket.once "listening", -> socket.setBroadcast true

        # Send packets!
        sendWol()

    # SERVICE DISCOVERY
    # -------------------------------------------------------------------------

    # When a new service is discovered on the network.
    onServiceUp: (service) =>
        logger.info "Network.onServiceUp", service.name

        # Try parsing and identifying the new service.
        try
            existingDevice = lodash.find @data.devices, (d) ->
                if service.adresses?
                    return service.addresses.indexOf(d.ip) >= 0 and (service.port is d.localPort or service.port is d.remotePort)
                else
                    return false

            # Create new device or update existing?
            if not existingDevice?
                logger.info "Network.onServiceUp", "New", service.name, service.addresses, service.port
                existingDevice = {id: service.name}
                isNew = true
            else
                logger.info "Network.onServiceUp", "Existing", service.name, service.addresses, service.port
                isNew = false

            # Set device properties.
            existingDevice.host = service.host
            existingDevice.addresses = service.addresses
            existingDevice.up = true
            existingDevice.mdns = true
        catch ex
            @logError "Network.onServiceUp", ex

        # New device? Add to devices list and dispatch event.
        @data.devices.push existingDevice if isNew

        # Save device data.
        @setData "devices", @data.devices

    # When a service disappears from the network.
    onServiceDown: (service) =>
        logger.info "Network.onServiceDown", service.name

        # Try parsing and identifying the removed service.
        try
            existingDevice = lodash.find @data.devices, (d) =>
                return lodash.contains(service.addresses, d.ip) and (service.port is d.localPort or service.port is d.remotePort)

            # Device found? Set it down and emit event.
            if existingDevice?
                existingDevice.up = false
                existingDevice.mdns = false
                @setData "devices", @data.devices
        catch ex
            @logError "Network.onServiceDown", ex


# Singleton implementation.
# -----------------------------------------------------------------------------
Network.getInstance = ->
    @instance = new Network() if not @instance?
    return @instance

module.exports = exports = Network.getInstance()