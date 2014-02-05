# NETWORK API
# -----------------------------------------------------------------------------
class Network extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    buffer = require "buffer"
    dgram = require "dgram"
    http = require "http"
    lodash = expresser.libs.lodash
    mdns = require "mdns"
    moment = expresser.libs.moment
    url = require "url"
    xml2js = require "xml2js"
    zombie = require "zombie"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Local network discovery and headless browsers.
    mdnsBrowser: null
    zombieBrowser: null

    # Holds the login cookie for the router.
    routerCookie: {timestamp: 0}

    # Holds user status (online true, offline false) based on their mobile
    # phones connected to the same network.
    userStatus: {}

    # Is it running on the expected local network, or remotely?
    isHome: true

    # Return a list of devices marked as offline (up=false).
    offlineDevices: =>
        result = []

        # Iterate network devices.
        for sKey, sData of @data
            for d in sData.devices
                result.push d if not d.up

        return result

    # INIT
    # -------------------------------------------------------------------------

    # Init the Network module.
    init: =>
        @mdnsBrowser = mdns.createBrowser mdns.tcp("http")
        @mdnsBrowser.on "serviceUp", @onServiceUp
        @mdnsBrowser.on "serviceDown", @onServiceDown

        # Set data and user statuses.
        @data = {devices: [], router: {}}

        @checkIP()
        @baseInit()

    # Start monitoring the network.
    start: =>
        @mdnsBrowser.start()
        @probeRouter()
        @baseStart()

    # Stop monitoring the network.
    stop: =>
        @mdnsBrowser.stop()
        @baseStop()

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
        ips = "0," + ips.join ","
        homeSubnet = settings.network.router?.ip?.substring 0, 7

        if not homeSubnet? or ips.indexOf(",#{homeSubnet}") < 0
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

    # Probe router for stats on connected LAN clients, WAN, etc.
    probeRouter: =>
        if @isHome
            routerUrl = settings.network.router.localUrl
        else
            routerUrl = settings.network.router.remoteUrl

        # Set POST body.
        body = {SERVICES: "RUNTIME.DEVICE.LANPCINFO,RUNTIME.PHYINF"}

        # Create a request helper, which is gonna be called whenever the login cookie is set.
        getRouterConfig = =>
            logger.debug "Network.probeRouter", "getRouterConfig", @routerCookie
            reqParams = {parseJson: false, isForm: true, body: body, cookie: @routerCookie.data}
            
            @makeRequest routerUrl + "getcfg.php", reqParams, (err, result) =>
                if not err?
                    xml2js.parseString result, {explicitArray: false}, (xmlErr, parsedJson) =>
                        if not xmlErr?
                            routerObj = {timestamp: moment().unix()}

                            # Iterate router response to create a friendly object.
                            # Looks complex but basically we're removing extra fields
                            # and unecessary arrays to make a nice devices list.
                            for m in parsedJson.postxml.module

                                # Parse connected LAN devices.
                                if m.service.toString() is "RUNTIME.DEVICE.LANPCINFO"
                                    routerObj.lanDevices = m.runtime.lanpcinfo.entry

                                # Parse connected Wifi devices.
                                else if m.service.toString() is "RUNTIME.PHYINF"

                                    # Parse wifi on 2.4 GHz.
                                    uidWifi = settings.network.router.uidWifi24g
                                    wifi24g = lodash.find m.runtime.phyinf, {uid: uidWifi}
                                    routerObj.wifi24g = wifi24g.media.clients.entry

                                    # Parse wifi on 2.4 GHz.
                                    uidWifi = settings.network.router.uidWifi5g
                                    wifi5g = lodash.find m.runtime.phyinf, {uid: uidWifi}
                                    routerObj.wifi5g = wifi5g.media.clients.entry

                            # Save router data.
                            @setData "router", routerObj

        # Check if router login cookie is still valid.
        # Start headless browser to get login cookie otherwise.
        if @routerCookie.timestamp < moment().subtract("s", 600).unix()
            if not @zombieBrowser?
                @zombieBrowser = new zombie {debug: settings.general.debug, silent: not settings.general.debug}

            # Browser calls inside a try - catch to avoid weird JS / headless problems.
            try
                @zombieBrowser.visit routerUrl, (err, browser) =>
                    if err?
                        logger.debug "Network.probeRouter", "Zombie error.", err

                    # Only fill form and proceed with login if password field is found.
                    else if @zombieBrowser.document?.getElementById("loginpwd")?
                        @zombieBrowser.fill "#loginpwd", settings.network.router.password
                        @zombieBrowser.pressButton "#noGAC", (e, browser) =>
                            @routerCookie.data = @zombieBrowser.cookies.toString()
                            @routerCookie.timestamp = moment().unix()
                            @zombieBrowser.close()
                            logger.debug "Network.probeRouter", "Login cookie set"

                            # Proceed to the router config XML after cookie is set.
                            getRouterConfig()
            catch ex
                logger.debug "Network.probeRouter", "Zombie error.", ex

        else
            # Proceed to the router config XML.
            getRouterConfig()

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
                callback err, result if callback?


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