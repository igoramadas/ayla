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

    hue = require "./api/hue.coffee"
    network = require "./api/network.coffee"
    ninja = require "./api/ninja.coffee"

    # PARSE AND EXECUTE
    # -------------------------------------------------------------------------

    # Parse and execute the specified command.
    execute: (cmd, options, callback) =>
        logger.debug "Commander.execute", cmd, options

        # Iterate all command triggers till it finds a matching one.
        for key, value of settings.commands
            for c in value
                if cmd.indexOf(c) >= 0
                    try
                        eval (this[key] options, callback)
                    catch ex
                        logger.error "Commander.execute", cmd, options, ex
                        callback ex if callback?

    # HOME (LIGHTS, WEATHER) COMMANDS
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

    # SYSTEM COMMANDS
    # -------------------------------------------------------------------------

    # Notify user of devices down.
    notifyNetworkDevicesDown: (options, callback) =>
        logger.info "Commander.notifyNetworkDevicesDown", options
        down = network.getOfflineDevices()

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