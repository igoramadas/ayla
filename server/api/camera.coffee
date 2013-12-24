# CAMERA
# -----------------------------------------------------------------------------
class Camera

    expresser = require "expresser"
    downloader = expresser.downloader
    logger = expresser.logger
    settings = expresser.settings

    data = require "../data.coffee"
    lodash = require "lodash"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Camera module.
    init: =>
        camerasPath = settings.path.data + "cameras.json"

    # SNAPS
    # -------------------------------------------------------------------------

    # Save a snapshop for the specified camera.
    saveSnap: (id, callback) =>
        cam = lodash.find data.cache.cameras, {id: id}

        # Wrong cam?
        if not cam?
            logger.error "Camera.saveSnap", id, "Camera does not exist."
            return callback "Camera #{id} does not exist."

        # Try saving the snapshop.
        now = moment().format "YYYYMMDD-HHmmss"
        saveTo = settings.path.data + "camerasnaps/#{id}-#{now}.jpg"
        downloader.download cam.url, saveTo, (err, result) =>
            callback err, result

    # Remove old snaps depending on the `snapsMaxAgeDays` setting.
    cleanSnaps: =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Camera.getInstance = ->
    @instance = new Camera() if not @instance?
    return @instance

module.exports = exports = Camera.getInstance()