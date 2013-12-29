# EMAIL ACTION: COMMAND
# -----------------------------------------------------------------------------
class EmailAction_Command

    expresser = require "expresser"
    logger = expresser.logger

    commander = require "../commander.coffee"

    # ACTIONS
    # -------------------------------------------------------------------------

    # Process command messages.
    process: (msg, callback) =>
        logger.debug "EmailAction_Command", msg

        # Only proceed if subject is valid.
        if not msg.subject? or msg.subject is ""
            logger.warn "EmailAction_Amazon", msg.attributes.id, "No subject, abort."
            callback null, false
            return false

        # Execute command.
        commander.execute msg.subject, msg.text, callback


# Exports (not singleton!)
# -----------------------------------------------------------------------------
module.exports = exports = EmailAction_Command