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

    # Holds timers and intervals.
    timers: {}

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

    # BASE IMPLEMENTATION
    # -------------------------------------------------------------------------

    # Helper to build an object with the requested data.
    getDataObjects: =>
        result = {}
        args = lodash.toArray arguments
        result[a] = @data[a] for a in args
        return result

    # Used to send alerts and general notifications to the user.
    notify: (subject, messages, callback) =>
        logger.info "#{@moduleName}.notify", subject, messages

        body = messages.join "\n" if lodash.isArray messages

        # Set message options and send email.
        msgOptions = {to: settings.email.toMobile, subject: subject, body: body}
        mailer.send msgOptions, (err, result) => callback err, result if callback?

    # Called whenever data gets updated, will emit to other modules using the Expresser
    # events and to clients using Socket.IO. If value is not set, get from the
    # current `data` object.
    dataUpdated: (property, value) =>
        if value?
            data = value
        else
            data = @data[property]

        # Set data timestamp.
        data.timestamp = moment().unix()

        # Only emit if data is valid.
        if data?
            sockets.emit "#{@moduleId}.#{property}", data
            events.emit "#{@moduleId}.#{property}", data
        else
            logger.debug "#{@moduleName}.emitData", property, "Data is null or not defined. Do not emit."


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseManager