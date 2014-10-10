# SOUNDCLOUD API
# -----------------------------------------------------------------------------
# NOT READY YET! Module to get and manage to playlists, tracks and profile data
# on SoundCloud.
# More info at http://www.soundcloud.com.
class SoundCloud extends (require "./baseapi.coffee")

    expresser = require "expresser"

    async = expresser.libs.async
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the SoundCloud module.
    init: =>
        @baseInit()

    # Start collecting data from SoundCloud.
    start: =>
        @baseStart()

    # Stop collecting data from SoundCloud.
    stop: =>
        @baseStop()

    # GET DEVICE DATA
    # ------------------------------------------------------------------------

    # Gets the list of the user's favorite tracks from SoundCloud.
    getFavorites: (callback) =>
        console.warn "NOT IMPLEMENTED"

# Singleton implementation.
# -----------------------------------------------------------------------------
SoundCloud.getInstance = ->
    @instance = new SoundCloud() if not @instance?
    return @instance

module.exports = exports = SoundCloud.getInstance()
