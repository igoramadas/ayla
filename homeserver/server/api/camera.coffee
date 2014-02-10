# CAMERA API
# -----------------------------------------------------------------------------
# Module to take snaps from cameras or other picture sources. The camera devices
# must be set on the settings.network.devices array with a type "camera".

class Camera extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    downloader = expresser.downloader
    logger = expresser.logger
    settings = expresser.settings

    fs = require "fs"
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    networkApi = require "./network.coffee"
    path = require "path"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Camera module and set snaps path.
    init: =>
        @baseInit()

    # Start the camera API jobs.
    start: =>
        fullpath = path.join __dirname, "../../", settings.path.cameraSnaps

        fs.exists fullpath, (exists) =>
            if exists?
                @snapsPath = fullpath
            else
                @snapsPath = settings.path.cameraSnaps

        @baseStart()

    # Stop the camera API jobs.
    stop: =>
        @baseStop()

    # SNAPS
    # -------------------------------------------------------------------------

    # Save a snapshop for the specified camera. If `cam` is a string, consider
    # it being the camera host.
    takeSnap: (cam, callback) =>
        if not cam?
            throw new Error "A camera must be specified."

        # Find camera.
        if lodash.isString cam
            cam = lodash.find settings.network.devices, {type: "camera", host: cam}

        # Wrong cam?
        if not cam?
            callback "Camera #{id} does not exist."
            return

        # Set save options.
        now = moment().format settings.camera.dateFormat
        saveTo = @snapsPath + "#{cam.host}.#{now}.jpg"

        # URL remote or local? Construct path using local IP or remote host, port and image path.
        if networkApi.isHome
            downloadUrl = "#{cam.ip}:#{cam.localPort}/#{cam.imagePath}"
        else
            downloadUrl = "#{settings.network.router.remoteHost}:#{cam.remotePort}/#{cam.imagePath}"

        # Camera needs auth?
        if cam.auth?
            downloadUrl = "http://#{cam.auth}@#{downloadUrl}"
        else
            downloadUrl = "http://#{downloadUrl}"

        # Save (download) a snap from the camera.
        downloader.download downloadUrl, saveTo, (err, result) =>
            if err?
                @logError "Camera.takeSnap", cam.host, err
            else
                logger.info "Camera.takeSnap", cam.host, now
                @setData cam.host, {filename: saveTo}

            callback err, result if callback?

    # Remove old snaps depending on the `snapsMaxAgeDays` setting.
    cleanSnaps: =>
        count = 0

        # Read snaps path to iterate and check files to be deleted.
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
                            count++
                            @logError "Camera.cleanSnaps", f, err if err?

            # Only log if count is greater than 0.
            if count > 0
                logger.info "Camera.cleanSnaps", "Deleted #{count} snaps."

    # JOBS
    # -------------------------------------------------------------------------

    # Take camera snaps every `snapsIntervalSeconds` seconds.
    jobTakeSnaps: =>
        cameras = lodash.filter settings.network.devices, {type: "camera"}
        count = lodash.size cameras

        if count < 1
            logger.info "Camera.jobTakeSnaps", "No cameras registered on the network."
        else
            logger.info "Camera.jobTakeSnaps", "#{count} cameras found."

            # Take a snap for each camera found.
            for c in cameras
                @takeSnap c unless c.enabled is false

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