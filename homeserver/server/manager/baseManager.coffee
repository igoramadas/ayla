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

    # Emit data to other modules using the Expresser events, and to clients using sockets.
    # If value is not set, get from the current `data` object.
    emitData: (property, value) =>
        if property.indexOf(".") > 0
            arr = property.split "."
        else
            arr = [property]

        # Iterate property name.
        if value?
            data = value
        else
            data = @data
            data = data[p] for p in arr

        # Only emit if data is valid.
        if data?
            sockets.emit "#{@moduleId}.data.#{property}", data
            events.emit "usermanager.user.status", data
        else
            logger.debug "#{@moduleName}.emitData", dataName, "Data is null or not defined. Do not emit."


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseManager