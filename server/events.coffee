# SERVER: EVENTS
# -----------------------------------------------------------------------------
# Central event dispatcher for modules and APIs.
class Events

    expresser = require "expresser"
    logger = expresser.logger


# Singleton implementation.
# -----------------------------------------------------------------------------
Events.getInstance = ->
    @instance = new Events() if not @instance?
    return @instance

module.exports = exports = Events.getInstance()