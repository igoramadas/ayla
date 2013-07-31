# ENDOMONDO
# -----------------------------------------------------------------------------

class Endomondo

    # Required modules.
    expresser = require "expresser"


# Singleton implementation.
# --------------------------------------------------------------------------
Endomondo.getInstance = ->
    @instance = new Endomondo() if not @instance?
    return @instance

module.exports = exports = Endomondo.getInstance()