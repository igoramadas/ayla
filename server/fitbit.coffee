# FITBIT
# -----------------------------------------------------------------------------

class Fitbit

    # Required modules.
    expresser = require "expresser"


# Singleton implementation.
# --------------------------------------------------------------------------
Fitbit.getInstance = ->
    @instance = new Fitbit() if not @instance?
    return @instance

module.exports = exports = Fitbit.getInstance()