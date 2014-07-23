# SERVER: COMMANDER
# -----------------------------------------------------------------------------
# Handles commands to the server (sent by email, SMS, twitter etc).
# The commands and phrases are defined on the commands.json file
# located on the root folder.
class Commander

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    lodash = expresser.libs.lodash

    # The commands list is loaded on init, from file commands.json.
    commands: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the commander.
    init: =>
        try
            @commands = require "../commands.json"
        catch ex
            logger.error "Commander.init", ex.message, ex.stack

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
        for key, value of @commands
            for c in value
                if cmd.indexOf(c) >= 0
                    try
                        if options? and lodash.isString options

                            # First try parsing options as json.
                            try
                                options = JSON.parse options

                            # Can't parse JSON? Try as multipart form data then.
                            catch ex1
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
                        logger.error "Commander.execute", cmd, options, ex.message, ex.stack
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
            events.emit "network.wol", tarantino.mac, tarantino.ip, (err, result) =>
                cError.push err if err?
                cResult.push result

        # Turn off all Hue lights.
        events.emit "hue.switchgrouplights", false, (err, result) =>
            cError.push err if err?
            cResult.push result

        # Turn off all RF sockets (execute all commands with short name having "Off").
        lightsFilter = (d) -> return d.shortName.indexOf("Off") >= 0 and d.shortName.indexOf("TV") < 0
        events.emit "ninja.actuate433", lightsFilter, (err, result) =>
            cError.push err if err?
            cResult.push result

        # Turn on TV coloured light. Will actuate RF having "TV" and "On" on the short name.
        tvLightFilter = (d) -> return d.shortName.indexOf("On") >= 0 and d.shortName.indexOf("TV") >= 0
        events.emit "ninja.actuate433", tvLightFilter, (err, result) =>
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

        events.emit "hue.switchgrouplights", false, (err, result) =>
            callback err, result if callback?

    # Turn the specified house lights on.
    turnLightsOn: (options, callback) =>
        logger.info "Commander.turnLightsOn", options

        events.emit "hue.switchgrouplights", true, (err, result) =>
            callback err, result if callback?


# Singleton implementation.
# -----------------------------------------------------------------------------
Commander.getInstance = ->
    @instance = new Commander() if not @instance?
    return @instance

module.exports = exports = Commander.getInstance()