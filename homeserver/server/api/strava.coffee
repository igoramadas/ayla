# STRAVA API
# NOT READY YET!!!
# -----------------------------------------------------------------------------
# Module to connect to Strava.
# More info at www.strava.com.
class Strava extends (require "./baseapi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the Strava module.
    init: =>
        @baseInit()

    # Start collecting data from Strava.
    start: =>
        @baseStart()

    # Stop collecting data from Strava.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # ------------------------------------------------------------------------

    # Gets the list of the user's favorite tracks from Strava.
    getProfile: (callback) =>
        console.warn "NOT IMPLEMENTED"

# Singleton implementation.
# -----------------------------------------------------------------------------
Strava.getInstance = ->
    @instance = new Strava() if not @instance?
    return @instance

module.exports = exports = Strava.getInstance()
