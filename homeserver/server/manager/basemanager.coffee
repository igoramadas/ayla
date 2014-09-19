# BASE MANAGER
# -----------------------------------------------------------------------------
# All managers (files under /manager) inherit from this BaseManager.
class BaseManager extends (require "../basemodule.coffee")

    expresser = require "expresser"

    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings
    sockets = expresser.sockets

    # HELPERS
    # -------------------------------------------------------------------------

    # Make sure the data received contains updated information by checking its timestamp.
    compareGetLastData: (newData, currentData) =>
        lastData = {timestamp: 0}
        dataFound = false

        if lodash.isArray newData.value
            for d in newData.value
                if not currentData.timestamp? or d.timestamp >= currentData.timestamp and d.timestamp >= lastData.timestamp
                    lastData = d
                    dataFound = true
        else if not currentData.timestamp? or newData.timestamp >= currentData.timestamp
            lastData = newData.value
            dataFound = true

        # Return null if no current data was found.
        if not dataFound
            return null
        else
            return lastData

    # NOTIFICATIONS
    # -------------------------------------------------------------------------

    # This is a callback helper to emit results and errors back to the client.
    emitResultSocket: (err, result) =>
        if err?
            sockets.emit "#{@moduleName}.error", err
        else
            sockets.emit "#{@moduleName}.result", result

    # Used to send alerts and general notifications to users.
    notify: (options, callback) =>
        expiryDate = moment().subtract(settings.modules.notifyExpireMinutes, "m").unix()

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
        events.emit "emailManager.send", {mobile: true, subject: options.subject, body: body}

        # Add to the notifications cache.
        @notifications[options.subject] = {options: options, timestamp: moment().unix()}

    # Called whenever data gets updated, will emit to other modules using the Expresser
    # events and to clients using Socket.IO. If value is not set, get from the
    # current `data` object.
    dataUpdated: (key, value) =>
        if value?
            data = value
        else
            data = @data[key]

        # Only emit if data is valid.
        if data?
            data.timestamp = moment().unix()
            sockets.emit "#{@moduleName}.data", key, data
            events.emit "#{@moduleName}.data", key, data
        else
            logger.debug "#{@moduleName}.emitData", key, "Data is null or not defined. Do not emit."

# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseManager
