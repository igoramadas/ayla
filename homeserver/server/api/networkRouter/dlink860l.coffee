# NETWORK ROUTER: D-LINK DIR-860L
# -----------------------------------------------------------------------------
# Network router wrapper for D-Link DIR-860L. Implements a `probe` method
# which is used by the Network API module to get data from the router.
class NetworkRouter_Dlink860L

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    utils = expresser.utils

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    xml2js = require "xml2js"
    zombie = require "zombie"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Headless Zombie browser to emulate a login on router admin page.
    zombieBrowser: null

    # Holds the login cookie for the router.
    cookie: {timestamp: 0}

    # GET NETWORK STATS
    # -------------------------------------------------------------------------

    # Probe router for stats on connected LAN clients, WAN, DHCP info etc.
    # The `routerUrl` is local or remote and passed by the Network API module.
    probe: (routerUrl, callback) =>
        body = {SERVICES: "RUNTIME.DEVICE.LANPCINFO,RUNTIME.PHYINF"}

        # Create a request helper, which is gonna be called whenever the login cookie is set.
        getRouterConfig = =>
            logger.debug "NetworkRouter.probe", "getRouterConfig", @cookie
            reqParams = {parseJson: false, isForm: true, body: body, cookie: @cookie.data}

            @makeRequest routerUrl + "getcfg.php", reqParams, (err, result) =>
                if err?
                    callback {requestError: err}
                else
                    xml2js.parseString result, {explicitArray: false}, (xmlErr, parsedJson) =>
                        if xmlErr?
                            callback {xmlError: xmlErr}
                        else
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

                            # Return router data to callback.
                            callback null, routerObj

        # Check if router login cookie is still valid.
        # Start headless browser to get login cookie otherwise.
        if @cookie.timestamp < moment().subtract("s", 600).unix()
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
                            @cookie.data = @zombieBrowser.cookies.toString()
                            @cookie.timestamp = moment().unix()
                            @zombieBrowser.close()
                            logger.debug "Network.probeRouter", "Login cookie set"

                            # Proceed to the router config XML after cookie is set.
                            getRouterConfig()
            catch ex
                logger.debug "Network.probeRouter", "Zombie error.", ex
                callback {exception: ex}

        else
            # Proceed to the router config XML.
            getRouterConfig()


# Exports
# -----------------------------------------------------------------------------
module.exports = exports = NetworkRouter_Dlink860L