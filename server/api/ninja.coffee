# NINJA BLOCKS
# -----------------------------------------------------------------------------
class Ninja

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    ninjablocks = require "ninja-blocks"

    # Create Ninja App/
    ninjaApp: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Ninja Blocks module.
    init: =>
        @ninjaApp = ninjablocks.app {user_access_token: settings.ninja.appSecret}


# Singleton implementation.
# -----------------------------------------------------------------------------
Ninja.getInstance = ->
    @instance = new Ninja() if not @instance?
    return @instance

module.exports = exports = Ninja.getInstance()