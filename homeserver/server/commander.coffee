# SERVER: COMMANDER
# -----------------------------------------------------------------------------
# Handles commands to the server (sent by email, SMS, twitter etc).
class Commander

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings

    hueApi = require "./api/hue.coffee"
    lodash = require "lodash"
    networkApi = require "./api/network.coffee"
    ninjaApi = require "./api/ninja.coffee"

    # PARSE AND EXECUTE
    # -------------------------------------------------------------------------

    # Helper to parse and execute the specified command. This is called by
    # external triggers (for example email action or SMS).
    execute: (cmd, options, callback) =>
        logger.debug "Commander.execute", cmd, options

        # Iterate all command triggers till it finds a matching one.
        for key, value of settings.commands
            for c in value
                if cmd.indexOf(c) >= 0
                    try
                        if options? and lodash.isString options

                            # First try parsing options as json.
                            try
                                options = JSON.parse options
                            # Can't parse JSON? Try as multipart form data then.
                            catch ex
                                parsedOptions = {}
                                arr = options.split ","

                                # Iterate all key / value pairs then update options.
                                for a in arr
                                    keyValue = a.split "="
                                    parsedOptions[keyValue[0]] = keyValue[1]
                                options = parsedOptions

                        # Execute!
                        eval (this[key] options, callback)
                    catch ex
                        logger.error "Commander.execute", cmd, options, ex
                        callback ex if callback?

    # HOME GENERAL
    # -------------------------------------------------------------------------

    # Set movie mode ON by turning off all lights, turning on the ambilight
    # behind the TV and starting XBMC.
    movieMode: (options, callback) =>
        logger.info "Commander.movieMode", options
        cError = []
        cResult = []

        # Get media server info (tarantino).
        tarantino = lodash.find settings.network?.devices, {hostname: "tarantino"}

        # Send wol command to the home server.
        if not tarantino?
            logger.warn "Commander.movieMode", "Media server (Tarantino) settings are not defined. Do not send WOL."
        else
            networkApi.wol tarantino.mac, (err, result) =>
                cError.push err if err?
                cResult.push result

        # Turn off all Hue lights.
        hueApi.switchAllLights false, (err, result) =>
            cError.push err if err?
            cResult.push result

        # Turn off all RF sockets (execute all commands with short name having "OFF").
        lightsFilter = (d) -> return d.shortName.indexOf("OFF") >= 0
        ninjaApi.actuate433 lightsFilter, (err, result) =>
            cError.push err if err?
            cResult.push result

        # Turn on TV coloured light. Will actuate RF having "TV" and "ON" on the short name.
        tvLightFilter = (d) -> return d.shortName.indexOf("TV") >= 0 and d.shortName.indexOf("ON") >= 0
        ninjaApi.actuate433 tvLightFilter, (err, result) =>
            cError.push err if err?
            cResult.push result

        # No errors? Set array to null.
        cError = null if cError.length < 1

        callback cError, cResult if callback?

    # HOME LIGHTS
    # -------------------------------------------------------------------------

    # Turn the specified house lights off.
    turnLightsOff: (options, callback) =>
        logger.info "Commander.turnLightsOff", options

        hueApi.switchAllLights false, (err, result) =>
            callback err, result if callback?

    # Turn the specified house lights on.
    turnLightsOn: (options, callback) =>
        logger.info "Commander.turnLightsOn", options

        hueApi.switchAllLights true, (err, result) =>
            callback err, result if callback?

    # SYSTEM COMMANDS
    # -------------------------------------------------------------------------

    # Notify user of devices down.
    notifyNetworkDevicesDown: (options, callback) =>
        logger.info "Commander.notifyNetworkDevicesDown", options
        down = networkApi.getOfflineDevices()

        # Set correct subject and message body based on device status.
        if down.length > 0
            subject = "There are #{down.length} devices down"
            body = ""
            for d in down
                body += d.id + ", " + d.localIP
        else
            subject = "No devices down on your networks"
            body = "All your devices seem to be running fine, congrats :-)"

        # Set message options and send email.
        msgOptions = {to: settings.email.toMobile, subject: subject, body: body}
        mailer.send msgOptions, (err, result) =>
            callback err, result if callback?

# Singleton implementation.
# -----------------------------------------------------------------------------
Commander.getInstance = ->
    @instance = new Commander() if not @instance?
    return @instance

module.exports = exports = Commander.getInstance()