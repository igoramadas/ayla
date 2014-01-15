# EMAIL ACTION: AMAZON
# -----------------------------------------------------------------------------
class EmailAction_Amazon

    expresser = require "expresser"
    logger = expresser.logger

    # ACTIONS
    # -------------------------------------------------------------------------

    # Process message from Amazon.
    process: (msg, callback) =>
        logger.debug "EmailAction_Amazon", msg


# Exports (not singleton!)
# -----------------------------------------------------------------------------
module.exports = exports = EmailAction_Amazon