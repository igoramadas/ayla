# NINJA
# -----------------------------------------------------------------------------
# Interactions with Ninja Blocks.

class Ninja

    # Required modules.
    expresser = require "expresser"
    ninjablocks = require "ninja-blocks"

    # Create Ninja App/
    ninjaApp = ninjablocks.app {user_access_token: expresser.settings.ninja.appSecret}


# Singleton implementation.
# -----------------------------------------------------------------------------
Ninja.getInstance = ->
    @instance = new Ninja() if not @instance?
    return @instance

module.exports = exports = Ninja.getInstance()