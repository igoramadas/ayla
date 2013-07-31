# WITHINGS
# -----------------------------------------------------------------------------

class Withings

    # Required modules.
    expresser = require "expresser"


# Singleton implementation.
# -----------------------------------------------------------------------------
Withings.getInstance = ->
    @instance = new Withings() if not @instance?
    return @instance

module.exports = exports = Withings.getInstance()