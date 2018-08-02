# NEURIO API
# -----------------------------------------------------------------------------
# Collect energy consumption data from Neurio.
# More info at http://neur.io
class Neurio extends (require "./baseapi.coffee")

    expresser = require "expresser"

    logger = expresser.logger
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the Neurio module.
    init: =>
        @baseInit()

    # Start collecting data from Neurio.
    start: =>
        @baseStart()

    # Stop collecting data from Neurio.
    stop: =>
        @baseStop()

# Singleton implementation.
# -----------------------------------------------------------------------------
Neurio.getInstance = ->
    @instance = new Neurio() if not @instance?
    return @instance

module.exports = exports = Neurio.getInstance()
