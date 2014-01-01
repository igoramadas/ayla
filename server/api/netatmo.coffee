# NETATMO API
# -----------------------------------------------------------------------------
class Netatmo extends (require "./apiBase.coffee")

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    async = require "async"
    http = require "http"
    lodash = require "lodash"
    moment = require "moment"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Netatmo module.
    init: =>
        @baseInit()

    # Start collecting weather data.
    start: =>
        @baseStart()

    # Stop collecting weather data.
    stop: =>
        @baseStop()


# Singleton implementation.
# -----------------------------------------------------------------------------
Netatmo.getInstance = ->
    @instance = new Netatmo() if not @instance?
    return @instance

module.exports = exports = Netatmo.getInstance()