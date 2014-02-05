# SERVER: COMMANDER
# -----------------------------------------------------------------------------
# Handles commands to the server (sent by email, SMS, twitter etc).
class Commander

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    hueApi = require "./api/hue.coffee"
    lodash = expresser.libs.lodash
    networkApi = require "./api/network.coffee"
    ninjaApi = require "./api/ninja.coffee"

    # PARSE AND EXECUTE
    # -------------------------------------------------------------------------

    # Helper to parse and execute the specified command. This is called by
    # external triggers (for example email action or SMS).
    execute: (cmd, options, callback) =>
        logger.debug "Commander.execute", cmd, options

        # Command exists as a function? Execute it.
        if lodash.isFunction @[cmd]
            return @[cmd] options, callback

        # Otherwise iterate all command triggers till it finds a matching one.
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
                        callback {err: ex, command: cmd, options: options} if callback?

    # HOME GENERAL
    # -------------------------------------------------------------------------

    # Set movie mode ON by turning off all lights, turning on the ambilight
    # behind the TV and starting XBMC.
    movieMode: (options, callback) =>
        logger.info "Commander.movieMode", options
        cError = []
        cResult = []

        # Get media server info (tarantino).
        tarantino = lodash.find settings.network?.devices, {host: "tarantino"}

        # Send wol command to the home server.
        if not tarantino?
            logger.warn "Commander.movieMode", "Media server (Tarantino) settings are not defined. Do not send WOL."
        else
            networkApi.wol tarantino.mac, tarantino.ip, (err, result) =>
                cError.push err if err?
                cResult.push result

        # Turn off all Hue lights.
        hueApi.switchAllLights false, (err, result) =>
            cError.push err if err?
            cResult.push result

        # Turn off all RF sockets (execute all commands with short name having "Off").
        lightsFilter = (d) -> return d.shortName.indexOf("Off") >= 0 and d.shortName.indexOf("TV") < 0
        ninjaApi.actuate433 lightsFilter, (err, result) =>
            cError.push err if err?
            cResult.push result

        # Turn on TV coloured light. Will actuate RF having "TV" and "On" on the short name.
        tvLightFilter = (d) -> return d.shortName.indexOf("TV") >= 0 and d.shortName.indexOf("On") >= 0
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


# Singleton implementation.
# -----------------------------------------------------------------------------
Commander.getInstance = ->
    @instance = new Commander() if not @instance?
    return @instance

module.exports = exports = Commander.getInstance()