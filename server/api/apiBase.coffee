# API BASE MODULE
# -----------------------------------------------------------------------------
class ApiBase

    expresser = require "expresser"
    logger = expresser.logger

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all errors that happened on the module.
    errors: {}

    # Sets if module is running (true) or suspended (false).
    running: false

    # GENERAL METHODS
    # -------------------------------------------------------------------------

    # Logs module errors.
    logError: =>
        id = arguments[0]

        @errors[id] = [] if not @errors[id]?
        @errors[id].push arguments

        logger.error.apply logger, arguments


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = ApiBase