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

    # Init the Camera module.
    init: =>
        @baseInit()

    # Start the Camera module and set snaps path..
    start: =>
        fullpath = path.join __dirname, "../../", settings.path.cameraSnaps

        fs.exists fullpath, (exists) =>
            if exists?
                @snapsPath = fullpath
            else
                @snapsPath = settings.path.cameraSnaps

        @baseStart()

    # Stop the Camera module.
    stop: =>
        @baseStop()

    # SNAPS
    # -------------------------------------------------------------------------

    # Save a snapshop for the specified camera. If `cam` is a string, consider
    # it being the camera host or IP.
    takeSnap: (cam, callback) =>
        if not cam?
            throw new Error "The argument cam must be specified."

        # Find camera by host or IP in case `cam` is a string.
        if lodash.isString cam
            cam = lodash.find settings.network.devices, {type: "camera", host: cam}
            cam = lodash.find settings.network.devices, {type: "camera", ip: cam} if not cam?

        # Camnot found? Stop here.
        if not cam?
            callback "Camera #{id} does not exist." if callback?
            return

        # Set save options. Is URL remote or local? Construct path using
        # local IP or remote host, port and image path.
        now = moment().format settings.camera.dateFormat
        saveTo = @snapsPath + "#{cam.host}.#{now}.jpg"

        if networkApi.isHome
            downloadUrl = "#{cam.ip}:#{cam.localPort}/#{cam.imagePath}"
        else
            downloadUrl = "#{settings.network.router.remoteHost}:#{cam.remotePort}/#{cam.imagePath}"

        # Camera needs auth?
        if cam.auth?
            downloadUrl = "http://#{cam.auth}@#{downloadUrl}"
        else
            downloadUrl = "http://#{downloadUrl}"

        # Save (download) a snap from the camera. Use the camera's host for the data key.
        downloader.download downloadUrl, saveTo, (err, result) =>
            if err?
                @logError "Camera.takeSnap", cam.host, err
            else
                @setData cam.host, {filename: saveTo}
                logger.info "Camera.takeSnap", cam.host, cam.ip

            callback err, result if callback?

    # Remove old snaps depending on the `snapsMaxAgeDays` setting.
    cleanSnaps: (olderThanDays, callback) =>
        count = 0
        olderThanDays = settings.camera.snapsMaxAgeDays ir not olderThanDays?

        # Read snaps path to iterate and check files to be deleted.
        fs.readdir @snapsPath, (err, files) =>
            if err?
                @logError "Camera.cleanSnaps", olderThanDays, err
                return

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
            else
                logger.info "Camera.cleanSnaps", "No old snaps were deleted."

    # JOBS
    # -------------------------------------------------------------------------

    # Take a snapshot for every registered camera.
    jobTakeSnaps: (job) =>
        cameras = lodash.filter settings.network.devices, {type: "camera"}
        count = lodash.size cameras

        if count < 1
            logger.info "Camera.jobTakeSnaps", "No cameras registered on the network."
        else
            logger.info "Camera.jobTakeSnaps", "#{count} cameras found."

            # Take a snap for each enabled camera.
            for c in cameras
                @takeSnap c unless c.enabled is false

    # Clean old snaps accordingly to `snapsMaxAgeDays` setting or job's args.
    jobCleanSnaps: (job) =>
        logger.info "Camera.jobCleanSnaps"

        @cleanSnaps job.args


# Singleton implementation.
# -----------------------------------------------------------------------------
Camera.getInstance = ->
    @instance = new Camera() if not @instance?
    return @instance

module.exports = exports = Camera.getInstance()