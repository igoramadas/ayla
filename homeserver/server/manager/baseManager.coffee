# MANAGER BASE MODULE
# -----------------------------------------------------------------------------
class BaseManager

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings
    sockets = expresser.sockets

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all downloaded / processed data for that particular module.
    data: {}

    # Holds all errors that happened on the module.
    errors: {}

    # Sets if module is running (true) or suspended (false).
    running: false

    # INIT
    # -------------------------------------------------------------------------

    # Called when the module inits.
    baseInit: =>
        @moduleName = @__proto__.constructor.name.toString()
        @moduleId = @moduleName.toLowerCase()

        # Log and start.
        logger.debug "#{@moduleName}.init"
        @start()

    # Called when the module starts.
    baseStart: =>
        @running = true

    # Called when the module stops.
    baseStop: =>
        @running = false

    # ALERTS AND NOTIFICATIONS
    # -------------------------------------------------------------------------

    # Used to send alerts and general notifications to the user.
    notify: (subject, messages, callback) =>
        logger.info "#{@moduleName}.notify", subject, messages

        body = messages.join "\n" if lodash.isArray messages

        # Set message options and send email.
        msgOptions = {to: settings.email.toMobile, subject: subject, body: body}
        mailer.send msgOptions, (err, result) => callback err, result if callback?


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseManager