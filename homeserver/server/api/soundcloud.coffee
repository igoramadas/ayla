# SOUNDCLOUD API
# NOT READY YET!!!
# -----------------------------------------------------------------------------
# Module to connect to tracks and profiles on SoundCloud.
# More info at www.soundcloud.com.
class SoundCloud extends (require "./baseapi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    async = expresser.libs.async
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the SoundCloud module.
    init: =>
        @baseInit()

    # Start collecting data from The SoundCloud.
    start: =>
        @baseStart()

    # Stop collecting data from The SoundCloud.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # ------------------------------------------------------------------------

    # Gets the list of the user's favorite tracks from SoundCloud.
    getFavorites: (callback) =>
        console.warn 1


# Singleton implementation.
# -----------------------------------------------------------------------------
SoundCloud.getInstance = ->
    @instance = new SoundCloud() if not @instance?
    return @instance

module.exports = exports = SoundCloud.getInstance()