# SERVER: COMMANDER
# -----------------------------------------------------------------------------
# Handles commands to the server (sent by email, SMS, twitter etc).
class Commander

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer

    data = require "./data.coffee"
    hue = require "./api/hue.coffee"
    ninja = require "./api/ninja.coffee"

    # PARSE AND EXECUTE
    # -------------------------------------------------------------------------

    # Parse and execute the specified command.
    execute: (cmd, options, callback) =>
        logger.debug "Commander.execute", cmd, options

        # Iterate all command triggers till it finds a matching one.
        for key, value of data.static["commands"]
            if value.indexOf(cmd) >= 0
                try
                    eval (this[key] options, callback)
                catch ex
                    logger.error "Commander.execute", cmd, options, ex
                    callback ex if callback?

    # COMMANDS
    # -------------------------------------------------------------------------

    # Turn the specified house lights off.
    turnLightsOff: (options, callback) =>
        logger.info "Commander.turnLightsOff", options
        hue.switchAllLights false, (err, result) =>
            callback err, result if callback?

    # Turn the specified house lights on.
    turnLightsOn: (options, callback) =>
        logger.info "Commander.turnLightsOn", options
        hue.switchAllLights true, (err, result) =>
            callback err, result if callback?


# Singleton implementation.
# -----------------------------------------------------------------------------
Commander.getInstance = ->
    @instance = new Commander() if not @instance?
    return @instance

module.exports = exports = Commander.getInstance()