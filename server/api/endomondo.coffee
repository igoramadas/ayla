# ENDOMONDO
# -----------------------------------------------------------------------------
class Endomondo

    expresser = require "expresser"
    logger = expresser.logger

    # AUTH
    # -------------------------------------------------------------------------

    auth: =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Endomondo.getInstance = ->
    @instance = new Endomondo() if not @instance?
    return @instance

module.exports = exports = Endomondo.getInstance()