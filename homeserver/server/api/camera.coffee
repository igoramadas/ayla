# CAMERA API
# -----------------------------------------------------------------------------
# Module to take snaps from webcams or local IP cameras. It will get all devices
# from `settings.network.devices` with a type `camera`.
class Camera extends (require "./baseapi.coffee")

    expresser = require "expresser"

    datastore = expresser.datastore
    downloader = expresser.downloader
    events = expresser.events
    fs = require "fs"
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    path = require "path"
    settings = expresser.settings

    # Path to a "no camera image"
    nocamPath = __dirname + "../../public/images/nocam.jpg"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Camera module and set custom routes.
    init: =>
        @baseInit()
        @routes.push {method: "get", path: ":host/last.jpg", render: "image", callback: @routeLastImage}
        @routes.push {method: "get", path: "random.jpg", render: "image", callback: @routeRandomImage}

    # Start the Camera module and set snaps path..
    start: =>
        fullpath = path.join __dirname, "../../", settings.path.cameraSnaps

        fs.exists fullpath, (exists) =>
            if exists?
                @snapsPath = fullpath
            else
                @snapsPath = settings.path.cameraSnaps

            @baseStart()

            # Take snaps on start?
            if settings.modules.getDataOnStart
                @takeAllSnaps()

    # Stop the Camera module.
    stop: =>
        @baseStop()

    # ROUTES
    # -------------------------------------------------------------------------

    # Route for /random.jpg, which returns the latest image from a random camera.
    routeRandomImage: (req) =>
        cams = lodash.filter settings.network.devices, {type: "camera"}

        if cams.length < 1
            return nocamPath
        else
            cam = cams[Math.floor(Math.random() * cams.length)]

            if not @data[cam.host]?
                return nocamPath
            else
                return @data[cam.host][0].value.filename

    # Route for /camera_host/last.jpg to return its latest image.
    # If camera is not found or has no images, return the default nocam.jpg.
    routeLastImage: (req) =>
        cam = @data[req.params.host]

        if not cam? or cam.length < 0
            return nocamPath
        else
            return cam[0].value.filename

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

        if datastore.NetworkApi?.isHome
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
                cam.filename = saveTo
                @setData cam.host, cam

            callback err, result if lodash.isFunction callback

    # Take a snapshot for every registered camera on the network.
    takeAllSnaps: =>
        cameras = lodash.filter settings.network.devices, {type: "camera"}
        count = lodash.size cameras

        if count < 1
            logger.info "Camera.takeAllSnaps", "No cameras registered on the network."
        else
            logger.info "Camera.takeAllSnaps", "Snaps from #{count} camera(s)."

            # Take a snap for each enabled camera.
            for c in cameras
                @takeSnap c unless c.enabled is false

    # Remove old snaps depending on the `snapsMaxAgeDays` setting.
    cleanSnaps: (olderThanDays, callback) =>
        count = 0
        olderThanDays = settings.camera.snapsMaxAgeDays ir not olderThanDays?

        hasCallback = lodash.isFunction callback

        # Read snaps path to iterate and check files to be deleted.
        fs.readdir @snapsPath, (err, files) =>
            if err?
                @logError "Camera.cleanSnaps", olderThanDays, err
                callback err if callback?
                return

            err = null

            # Iterate all camera snap files.
            for f in files
                do (f) =>
                    datePart = f.split "."
                    datePart = datePart[datePart.length - 2]

                    # Define comparions dates.
                    minDate = moment().subtract settings.camera.snapsMaxAgeDays, "d"
                    fileDate = moment datePart, settings.camera.dateFormat

                    # If older than the target date, delete the file.
                    if fileDate.isBefore minDate
                        try
                            fs.unlinkSync @snapsPath + f
                            count++
                        catch ex
                            err = ex
                            @logError "Camera.cleanSnaps", f, ex.message, ex.stack

            # Only log if count is greater than 0.
            if count > 0
                logger.info "Camera.cleanSnaps", "Deleted #{count} snaps."
            else
                logger.info "Camera.cleanSnaps", "No old snaps were deleted."

            callback err, count if hasCallback

# Singleton implementation.
# -----------------------------------------------------------------------------
Camera.getInstance = ->
    @instance = new Camera() if not @instance?
    return @instance

module.exports = exports = Camera.getInstance()
