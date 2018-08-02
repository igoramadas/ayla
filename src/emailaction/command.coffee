# EMAIL ACTION: COMMAND
# -----------------------------------------------------------------------------
class EmailAction_Command

    expresser = require "expresser"
    logger = expresser.logger

    commander = require "../commander.coffee"

    # ACTIONS
    # -------------------------------------------------------------------------

    # Process command messages.
    process: (account, parsedMsg, callback) =>
        if not parsedMsg.subject? or parsedMsg.subject is ""
            logger.warn "EmailAction_Command", parsedMsg.attributes.id, "No subject on message. Abort!"
            return callback null, false

        # Execute command.
        commander.execute parsedMsg.subject, parsedMsg.text, callback

# Exports
# -----------------------------------------------------------------------------
module.exports = exports = EmailAction_Command
