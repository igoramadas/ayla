# MANAGER BASE MODULE
# -----------------------------------------------------------------------------
class BaseManager

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all downloaded / processed data for that particular module.
    data: {}

    # Holds timers and intervals.
    timers: {}

    # Holds recent errors that happened on the module.
    errors: {}

    # Holds recent notifications sent by the module.
    notifications: {}

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

    # NOTIFICATIONS
    # -------------------------------------------------------------------------

    # Used to send alerts and general notifications to the user.
    notify: (options, callback) =>
        expiryDate = moment().subtract("m", settings.general.moduleNotifyExpireMinutes).unix()

        # Check if same notification was sent recently. If so, abort here.
        if @notifications[options.subject]?.timestamp > expiryDate
            logger.debug "#{@moduleName}.notify", options.subject, "Abort! Notification was sent recently."
            return
        else
            logger.info "#{@moduleName}.notify", options.subject

        # Merge message with blank lines if passed as array.
        if lodash.isArray options.message
            body = options.message.join "\n"
        else
            body = options.message

        # Set message options and send email.
        events.emit "emailmanager.send", {mobile: true, subject: options.subject, body: body}

        # Add to the notifications cache.
        @notifications[options.subject] = {options: options, timestamp: moment().unix()}

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