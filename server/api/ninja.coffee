# NINJA BLOCKS
# -----------------------------------------------------------------------------
class Ninja

    expresser = require "expresser"
    logger = expresser.logger

    ninjablocks = require "ninja-blocks"

    # Create Ninja App/
    ninjaApp = ninjablocks.app {user_access_token: expresser.settings.ninja.appSecret}

    # AUTH
    # -------------------------------------------------------------------------

    auth: =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Ninja.getInstance = ->
    @instance = new Ninja() if not @instance?
    return @instance

module.exports = exports = Ninja.getInstance()