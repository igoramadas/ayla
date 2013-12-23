# WITHINGS
# -----------------------------------------------------------------------------
class Withings

    expresser = require "expresser"
    logger = expresser.logger

    # AUTH
    # -------------------------------------------------------------------------

    auth: =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Withings.getInstance = ->
    @instance = new Withings() if not @instance?
    return @instance

module.exports = exports = Withings.getInstance()