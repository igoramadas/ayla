# CAMERA API
# -----------------------------------------------------------------------------
class Camera extends (require "./apiBase.coffee")

    expresser = require "expresser"
    downloader = expresser.downloader
    logger = expresser.logger
    settings = expresser.settings

    data = require "../data.coffee"
    fs = require "fs"
    lodash = require "lodash"
    path = require "path"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Path where camera snaps are saved.
    snapsPath: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Camera module and set snaps path.
    init: =>
        @snapsPath = settings.path.data + "cameraSnaps/"
        @baseInit()

    # Start the camera API jobs.
    start: =>
        @baseStart()

    # Stop the camera API jobs.
    stop: =>
        @baseStop()

    # SNAPS
    # -------------------------------------------------------------------------

    # Save a snapshop for the specified camera.
    takeSnap: (id, callback) =>
        if not id?
            throw new Error "The camera id must be specified."

        # Find camera.
        id = id.id if id.id?
        cam = lodash.find data.cache.cameras, {id: id}

        # Wrong cam?
        if not cam?
            errorMsg = "Camera #{id} does not exist."
            @logError "Camera.saveSnap", errorMsg
            callback errorMsg
            return false

        # Set save options.
        now = moment().format settings.camera.dateFormat
        saveTo = @snapsPath + "#{id}.#{now}.jpg"

        # Save (download) a snap from the camera.
        downloader.download cam.url, saveTo, (err, result) =>
            if err?
                @logError "Camera.saveSnap", id, err
            else
                logger.info "Camera.saveSnap", id, now
            callback err, result if callback?

    # Remove old snaps depending on the `snapsMaxAgeDays` setting.
    cleanSnaps: =>
        logger.info "Camera.cleanSnaps"

        fs.readdir @snapsPath, (err, files) =>
            if err?
                @logError "Camera.cleanSnaps", err
                return false

            # Iterate all camera snap files.
            for f in files
                do (f) =>
                    datePart = f.split "."
                    datePart = datePart[datePart.length - 2]

                    # Define comparions dates.
                    minDate = moment().subtract "d", settings.camera.snapsMaxAgeDays
                    fileDate = moment datePart, settings.camera.dateFormat

                    # If older than the target date, delete the file.
                    if fileDate.isBefore minDate
                        fs.unlink @snapsPath + f, (err) =>
                            @logError "Camera.cleanSnaps", f, err if err?

    # JOBS
    # -------------------------------------------------------------------------

    # Take camera snaps every `snapsIntervalSeconds` seconds.
    jobTakeSnaps: =>
        logger.info "Camera.jobTakeSnaps"
        for c in data.cache.cameras
            @takeSnap c.id if c.enabled

    # Clean old snaps twice a day.
    jobCleanSnaps: =>
        logger.info "Camera.jobCleanSnaps"
        @cleanSnaps()


# Singleton implementation.
# -----------------------------------------------------------------------------
Camera.getInstance = ->
    @instance = new Camera() if not @instance?
    return @instance

module.exports = exports = Camera.getInstance()