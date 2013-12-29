# SERVER: COMMANDER
# -----------------------------------------------------------------------------
# Handles commands to the server (sent by email, SMS, twitter etc).
class Commander

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer

    hue = require "./api/hue.coffee"
    ninja = require "./api/ninja.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Parse and execute the specified command.
    execute: (cmd, options, callback) =>
        logger.debug "Commander.execute", cmd, options

        if cmd.indexOf("turn lights off") >= 0
            @turnLightsOff options, callback

    # COMMANDS
    # -------------------------------------------------------------------------

    # Turn the specified house lights off.
    turnLightsOff: (options, callback) =>
        logger.info "Commander.turnLightsOff", options
        hue.switchLight false, (err, result) =>
            callback err, result

    # Turn the specified house lights on.
    turnLightsOn: (options, callback) =>
        logger.info "Commander.turnLightsOn", options
        hue.switchLight true, (err, result) =>
            callback err, result


# Singleton implementation.
# -----------------------------------------------------------------------------
Commander.getInstance = ->
    @instance = new Commander() if not @instance?
    return @instance

module.exports = exports = Commander.getInstance()