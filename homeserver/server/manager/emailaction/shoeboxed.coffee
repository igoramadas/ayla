# EMAIL ACTION: SHOEBOXED
# -----------------------------------------------------------------------------
class EmailAction_Shoeboxed

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger

    description: "Forward invoices and bills to Shoeboxed."

    # ACTIONS
    # -------------------------------------------------------------------------

    # Process invoices and send automatically to Shoeboxed.
    process: (account, parsedMsg, callback) =>
        if not settings.shoeboxed?.email?
            logger.warn "EmailAction_Shoeboxed", "Shoeboxed email setting is not defined. Abort!"
            return callback null, false

        # Message must have attachments.
        if not parsedMsg.attachments? or parsedMsg.attachments.length < 1
            logger.warn "EmailAction_Shoeboxed", parsedMsg.attributes.id, "Message has no attachment. Abort!"
            return callback null, false

        # Create message object and dispatch send event.
        body = "Forwarded automatically by Ayla."
        msg = {to: settings.shoeboxed.email, subject: parsedMsg.subject, attachments: parsedMsg.attachments, body: body}
        events.emit "emailManager.send", msg, (err, result) => callback err, result


# Exports
# -----------------------------------------------------------------------------
module.exports = exports = EmailAction_Shoeboxed
