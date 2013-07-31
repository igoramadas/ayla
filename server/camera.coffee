# CAMERA
# -----------------------------------------------------------------------------

class Camera

    # Required modules.
    expresser = require "expresser"


# Singleton implementation.
# -----------------------------------------------------------------------------
Camera.getInstance = ->
    @instance = new Camera() if not @instance?
    return @instance

module.exports = exports = Camera.getInstance()