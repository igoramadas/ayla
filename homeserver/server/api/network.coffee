# NETWORK API
# -----------------------------------------------------------------------------
# Module for internal network management and discovery. Please note that a few
# other API modules depend on this Network module to work, so unless you have a
# very specific use case please leave it on the `settings.modules.enabled` list.
# You'll also need to define a specific wrapper for your network router, by
# default it supports the D-Link DIR-860L model.
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
    xml2js = require "xml2js"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Local network discovery and router model object.
    mdnsBrowser: null
    router: null

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

        @baseInit {devices: [], router: {}}

    # Start monitoring the network.
    start: =>
        @mdnsBrowser.on "serviceUp", @onServiceUp
        @mdnsBrowser.on "serviceDown", @onServiceDown
        @mdnsBrowser.start()
        @setRouter()

        @baseStart()

    # Stop monitoring the network.
    stop: =>
        @mdnsBrowser.off "serviceUp", @onServiceUp
        @mdnsBrowser.off "serviceDown", @onServiceDown
        @mdnsBrowser.stop()

        @baseStop()

    # Set router implementation. Get router model, or use default
    # (first file found under the /api/networkRouter folder).
    setRouter: =>
        if not settings.network.router?.model?
            logger.warn "Network.setRouter", "No specific router model was set. Will use default: dlink860l."
            model = "dlink860l"
        else
            model = settings.network.router.model

        # Get router class and instantiate it.
        try
            routerClass = require "./networkRouter/#{model}.coffee"
            @router = new routerClass
            @probeRouter()
        catch ex
            @logError "Network.setRouter", model, ex

    # GET NETWORK STATS
    # -------------------------------------------------------------------------

    # Check if Ayla server is on the home network.
    checkIP: =>
        if not settings.network?
            logger.warn "Network.checkIP", "Network settings are not defined. Skip!"
            return
        else
            logger.debug "Network.checkIP", "Expected home IP: #{settings.network.ip}"

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
    probeDevices: =>
        for nKey, nData of settings.network
            @data[nKey] = lodash.cloneDeep(nData) if not @data[nKey]?

            # Iterate network devices.
            if @data[nKey].devices?
                @checkDevice d for d in @data[nKey].devices

    # Probe router data.
    probeRouter: (callback) =>
        if not @isRunning [@router]
            callback "Module not running or Router wrapper not started. Please check Network and router settings." if callback?
            return

        # Get correct router URL depending if running at home or not.
        if @isHome
            routerUrl = settings.network.router.localUrl
        else
            routerUrl = settings.network.router.remoteUrl

        # Probe and set the `router` data.
        @router.probe routerUrl, (err, result) =>
            if err?
                @logError "Network.probeRouter", err
            else
                @setData "router", result

            callback err, result if lodash.isFunction callback

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
        socketErr = null
        socketResult = null

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
        logger.debug "Network.onServiceUp", service

        # Try parsing and identifying the new service.
        try
            for sKey, sData of @data
                if sData.devices?
                    existingDevice = lodash.find sData.devices, (d) ->
                        if service.adresses?
                            return service.addresses.indexOf(d.ip) >= 0 and service.port is d.localPort
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

        @data.devices.push existingDevice if isNew

    # When a service disappears from the network.
    onServiceDown: (service) =>
        logger.info "Network.onServiceDown", service.name

        # Try parsing and identifying the removed service.
        try
            for sKey, sData of @data
                existingDevice = lodash.find sData.devices, (d) =>
                    return service.addresses.indexOf d.ip >= 0 and service.port is d.localPort

                if existingDevice?
                    existingDevice.up = false
                    existingDevice.mdns = false
        catch ex
            @logError "Network.onServiceDown", ex

    # JOBS
    # -------------------------------------------------------------------------

    # Keep probing network devices every few seconds.
    jobProbeDevices: =>
        @probeDevices()

    # Keep probing network router every few seconds.
    jobProbeRouter: =>
        @probeRouter()


# Singleton implementation.
# -----------------------------------------------------------------------------
Network.getInstance = ->
    @instance = new Network() if not @instance?
    return @instance

module.exports = exports = Network.getInstance()