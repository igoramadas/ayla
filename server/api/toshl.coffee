# TOSHL
# -----------------------------------------------------------------------------
class Toshl

    expresser = require "expresser"
    logger = expresser.logger

    # AUTH
    # -------------------------------------------------------------------------

    auth: =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Toshl.getInstance = ->
    @instance = new Toshl() if not @instance?
    return @instance

module.exports = exports = Toshl.getInstance()