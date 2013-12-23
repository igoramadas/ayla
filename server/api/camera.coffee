# CAMERA
# -----------------------------------------------------------------------------
class Camera

    expresser = require "expresser"
    logger = expresser.logger

    # AUTH
    # -------------------------------------------------------------------------

    auth: =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Camera.getInstance = ->
    @instance = new Camera() if not @instance?
    return @instance

module.exports = exports = Camera.getInstance()