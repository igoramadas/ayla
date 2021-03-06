# NETWORK API
# -----------------------------------------------------------------------------
# Module for devices management and discovery. This is considered a core module
# of the server and should be left enabled unless you have very specific reasons
# not to do so. Bluetooth related methods require the `BlueZ` package on Linux
# and `Bluetooth Command Line Tools` on Windows.
class Network extends (require "./baseapi.coffee")

    expresser = require "expresser"

    async = expresser.libs.async
    datastore = expresser.datastore
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings
    utils = expresser.utils

    appData = require "../appdata.coffee"
    buffer = require "buffer"
    dgram = require "dgram"
    fs = require "fs"
    http = require "http"
    noble = require "noble"
    path = require "path"
    querystring = require "querystring"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # MDNS might be unavailable in some systems.
    mdns = null

    try
        mdns = require "mdns"
    catch ex
        logger.warn "Network.MDNS", "MDNS module is not available :-("

    # Local network discovery.
    mdnsBrowser: null

    # Server information cache.
    serverInfo: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the Network module.
    init: =>
        @baseInit {isHome: true, devices: []}

        @routes.push {method: "get", path: "userpresence", render: "json", callback: @routeUserPresence}
        @routes.push {method: "get", path: "userlocation", render: "json", callback: @routeUserLocation}

    # Start monitoring the network.
    start: =>
        @baseStart()

        events.on "Network.wol", @wol

        @checkIP()

        @serverInfo = utils.system.getInfo()
        @serverInfo.platform = @serverInfo.platform.toLowerCase()

        if mdns?
            @mdnsBrowser = mdns.createBrowser mdns.tcp "http"

        if @mdnsBrowser? and settings.network.autoDiscovery
            @mdnsBrowser.on "serviceUp", @onServiceUp
            @mdnsBrowser.on "serviceDown", @onServiceDown
            @mdnsBrowser.start()

        noble.startScanning()
        noble.on "discover", @bluetoothDiscovered

        @probeDevices()

    # Stop monitoring the network.
    stop: =>
        events.off "Network.wol", @wol

        noble.off "discover", @bluetoothDiscovered
        noble.stopScanning()

        if @mdnsBrowser? and settings.network.autoDiscovery
            @mdnsBrowser.off "serviceUp", @onServiceUp
            @mdnsBrowser.off "serviceDown", @onServiceDown
            @mdnsBrowser.stop()

        @baseStop()

    # ROUTES
    # -------------------------------------------------------------------------

    # Route to set user presence, mainly called when user is identified as
    # online or offline by checking bluetooth devices.
    routeUserPresence: (req) =>
        result = []

        for username, online of req.query
            if username isnt "token"
                user = settings.users[username]

                if not user?
                    logger.warn "Network.routeUserPresence", "User not found: #{username}"
                    result.push "User #{username} not found."
                else
                    @setData "userPresence", {user: user.name, online: online}, username
                    logger.info "Network.routeUserPresence", username, online
                    result.push "#{username}: #{online}"

        return {result: result}

    # Route to set user location.
    routeUserLocation: (req) =>
        result = []

        for username, location of req.query
            if username isnt "token"
                user = settings.users[username]

                if not user?
                    logger.warn "Network.routeUserLocation", "User not found: #{username}"
                    result.push "User #{username} not found."
                else
                    @setData "userLocation", {user: user.name, location: location}, username
                    logger.info "Network.routeUserLocation", username, location
                    result.push "#{username}: #{location}"

        return {result: result}

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
        ips = utils.system.getIP()
        ips = ips.join ","
        homeSubnet = settings.network.router?.ip?.substring 0, 7

        if not homeSubnet? or ips.indexOf(homeSubnet) < 0
            @data.isHome = false
        else
            @data.isHome = true

        logger.info "Network.checkIP", ips, "isHome = #{@data.isHome}"

    # Check if the specified device / server / URL is up.
    # Abort if device is invalid or was found using mdns.
    checkDevice: (device) =>
        return if not device? or device.mdns

        logger.debug "Network.checkDevice", device

        # Are addresses set?
        if not device.addresses?
            device.addresses = []
            device.addresses.push device.ip

        # Not checked yet? Set `up` to false.
        device.up = false if not device.up?

    # Probe the current network and check device statuses.
    probeDevices: (callback) =>
        logger.debug "Network.probeDevices"

        @checkDevice d for d in appData.network.devices

    # WAKE-ON-LAN
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
        if not mac? or not mac.match /[^a-fA-F0-9]/
            errMsg = "The specified MAC address #{mac} is not valid."
            logger.error "Network.wol", errMsg
            callback errMsg
            return

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

    # BLUETOOTH
    # -------------------------------------------------------------------------

    # Query bluetooth and returns all discoverable devices.
    bluetoothDiscovered: (device) =>
        name = id = device.advertisement?.localName or device.id

        if device.address is "unknown"
            return logger.debug "Network.bluetoothDiscovered", "Unknown device", name

        logger.info "Network.bluetoothDiscovered", name, device.address

        existingDevice = lodash.find @data.devices, {address: device.address}

        if existingDevice?
            index = @data.devices.indexOf existingDevice
            @data.devices.splice index, 1

        @data.devices.push device

    # SERVICE DISCOVERY
    # -------------------------------------------------------------------------

    # When a new service is discovered on the network.
    onServiceUp: (service) =>
        logger.debug "Network.onServiceUp", service.name

        # Try parsing and identifying the new service.
        try
            existingDevice = lodash.find @data.devices, (d) ->
                if lodash.indexOf(service.addresses, d.ip) < 0
                    return false
                if service.port isnt d.port
                    return false
                return true

            # Create new device or update existing?
            if not existingDevice?
                logger.info "Network.onServiceUp", "New", service.name, service.addresses, service.port
                existingDevice = {description: service.name}
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
            logger.error "Network.onServiceUp", ex

        # New device? Add to devices list and dispatch event.
        @data.devices.push existingDevice if isNew

    # When a service disappears from the network.
    onServiceDown: (service) =>
        logger.info "Network.onServiceDown", service.name

        # Try parsing and identifying the removed service.
        try
            existingDevice = lodash.find @data.devices, (d) ->
                if lodash.indexOf(service.addresses, d.ip) < 0
                    return false
                if service.port isnt d.port
                    return false
                return true

            # Device found? Set it down and emit event.
            if existingDevice?
                existingDevice.up = false
                existingDevice.mdns = false
        catch ex
            logger.error "Network.onServiceDown", ex

# Singleton implementation.
# -----------------------------------------------------------------------------
Network.getInstance = ->
    @instance = new Network() if not @instance?
    return @instance

module.exports = exports = Network.getInstance()
