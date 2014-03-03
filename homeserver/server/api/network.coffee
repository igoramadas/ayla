# NETWORK API
# -----------------------------------------------------------------------------
# Module for internal network management and discovery. Please note that a few
# other API modules depend on this Network module to work, so unless you have a
# very specific use case please leave it on the `settings.modules.enabled` list.
# Bluetooth methods require BlueZ package on Linux and Bluetooth Command Line Tools on Windows.
class Network extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    async = expresser.libs.async
    buffer = require "buffer"
    cprocess = require "child_process"
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

    # Is it running on the expected local network, or remotely?
    isHome: true

    # Server information cache.
    serverInfo: {}

    # Holds user status (online true, offline false) based on their mobile
    # phones connected to the same network.
    userStatus: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the Network module.
    init: =>
        @mdnsBrowser = mdns.createBrowser mdns.tcp("http")
        @checkIP()

        @baseInit {devices: []}

    # Start monitoring the network.
    start: =>
        @serverInfo = utils.getServerInfo()
        @serverInfo.platform = @serverInfo.platform.toLowerCase()

        if settings.network.autoDiscovery
            @mdnsBrowser.on "serviceUp", @onServiceUp
            @mdnsBrowser.on "serviceDown", @onServiceDown
            @mdnsBrowser.start()

        @baseStart()

        if settings.modules.getDataOnStart
            @probeDevices()
            @probeBluetooth()
            @probeBluetoothUsers()

    # Stop monitoring the network.
    stop: =>
        if settings.network.autoDiscovery
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

    # BLUETOOTH
    # -------------------------------------------------------------------------

    # Query bluetooth and returns all discoverable devices.
    probeBluetooth: (callback) =>
        if not lodash.isFunction callback
            callback = null

        # Scan and parse results from command line.
        # Use btdiscovery on Windows, hcitool on Linux.
        try
            if @serverInfo.platform.indexOf("linux") < 0
                cmd = "btdiscovery"
            else
                cmd = "hcitool scan"

            # On close parse the output and get device mac and names out of it.
            scan = cprocess.exec cmd, (err, stdout, stderr) =>
                if err?
                    @logError "Network.probeBluetooth", err
                else if stderr
                    @logError "Network.probeBluetooth", stderr
                else
                    devices = []
                    lines = stdout.split "\n"

                    # First line is the "Scanning..." string.
                    lines.shift()

                    # Iterate devices.
                    for d in lines
                        devices.push d.replace("\t", " ").trim() if d? and d isnt ""

                    @setData "bluetooth", devices

                    callback null, devices if callback?
        catch ex
            @logError "Network.probeBluetooth", ex
            callback ex if callback?

    # Probe user's bluetooth devices by checking the `bluetooth` property of registered users.
    probeBluetoothUsers: (callback) =>
        if not lodash.isFunction callback
            callback = null

        macs = []
        tasks = []

        # Iterate users and get bluetooth mach addresses.
        for username, user of settings.users
            macs.push {user: username, mac: user.bluetooth} if user.bluetooth?

        # Iterate and create tasks for each passed mac address.
        for d in macs
            do (d) =>
                tasks.push (cb) =>
                    try
                        if @serverInfo.platform.indexOf("linux") < 0
                            cmd = "btdiscovery -b#{d.mac} -d%n%"
                        else
                            cmd = "hcitool name #{d.mac}"

                        # On close parse the output and get device name, and set its online property.
                        # If name is found, add `deviceName` to the original object.
                        scan = cprocess.exec cmd, (err, stdout, stderr) =>
                            if err?
                                @logError "Network.probeBluetoothUsers", err
                            else if stderr
                                @logError "Network.probeBluetoothUsers", stderr
                            else if stdout? and stdout isnt ""
                                d.deviceName = stdout.trim()
                                logger.info "Network.probeBluetoothUsers", d.user, d.deviceName, "online!" if not d.online
                                d.online = true
                            else
                                d.online = false
                            cb null, d
                    catch ex
                        cb ex

        # Check all passed bluetooth devices.
        async.series tasks, (err, results) =>
            if err?
                @logError "Network.probeBluetoothUsers", err
            else
                @setData "bluetoothUsers", results

            callback err, results if callback?

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
                if service.port isnt d.localPort and service.port isnt d.remotePort
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
            @logError "Network.onServiceUp", ex

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
                if service.port isnt d.localPort and service.port isnt d.remotePort
                    return false
                return true

            # Device found? Set it down and emit event.
            if existingDevice?
                existingDevice.up = false
                existingDevice.mdns = false
        catch ex
            @logError "Network.onServiceDown", ex


# Singleton implementation.
# -----------------------------------------------------------------------------
Network.getInstance = ->
    @instance = new Network() if not @instance?
    return @instance

module.exports = exports = Network.getInstance()