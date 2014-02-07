# EMAIL ACTION: SHOEBOXED
# -----------------------------------------------------------------------------
class EmailAction_Shoeboxed

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger

    # ACTIONS
    # -------------------------------------------------------------------------

    # Process invoices and send automatically to Shoeboxed.
    process: (account, parsedMsg, callback) =>
        if not parsedMsg.attachments? or parsedMsg.attachments.length < 1
            logger.warn "EmailAction_Shoeboxed", parsedMsg.attributes.id, "Message has no attachment. Abort!"
            return callback null, false

        # Shoeboxed email settings must be defined.
        if not settings.shoeboxed?.email?
            logger.warn "EmailAction_Shoeboxed", parsedMsg.attributes.id, "Shoeboxed email setting is not defined. Abort!"
            return callback null, false

        # Create message object and dispatch send event.
        msg = {to: settings.shoeboxed.email, subject: parsedMsg.subject, attachments: parsedMsg.attachments}
        events.emit "emailmanager.send", msg, (err, result) => callback err, result


# Exports (not singleton!)
# -----------------------------------------------------------------------------
module.exports = exports = EmailAction_Shoeboxed