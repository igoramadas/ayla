# EMAIL ACTION: SHOEBOXED
# -----------------------------------------------------------------------------
class EmailAction_Shoeboxed

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

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
            logger.warn "EmailAction_Shoeboxed", parsedMsg.from.address, parsedMsg.subject, "Message has no attachment. Abort!"
            return callback null, false

        logger.info "EmailAction_Shoeboxed", parsedMsg.from.address, parsedMsg.subject

        # Create message object and dispatch send event.
        msg = {to: settings.shoeboxed.email, subject: parsedMsg.subject, attachments: parsedMsg.attachments, body: parsedMsg.html}
        events.emit "EmailManager.send", msg, (err, result) => callback err, result

# Exports
# -----------------------------------------------------------------------------
module.exports = exports = EmailAction_Shoeboxed
