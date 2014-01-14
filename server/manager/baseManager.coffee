# MANAGER BASE MODULE
# -----------------------------------------------------------------------------
class BaseManager

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all downloaded / processed data for that particular module.
    data: {}

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
        cron.start {module: "#{@moduleId}.coffee"}

    # Called when the module stops.
    baseStop: =>
        @running = false
        cron.stop {module: "#{@moduleId}.coffee"}


# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseManager