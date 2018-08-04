# SERVER: APPDATA
# -----------------------------------------------------------------------------
# Central module that holds general app data.
class AppData

    expresser = require "expresser"
    logger = expresser.logger
    utils = expresser.utils

    fs = require "fs"
    path = require "path"

    # INIT
    # -------------------------------------------------------------------------

    # Load initial data from the /data folder.
    init: =>
        return new Promise (resolve, reject) =>
            dataPath = path.resolve __dirname, "../data"

            fs.readdir dataPath, (err, files) =>
                if err?
                    logger.error "AppData.init", err
                    return reject err

                for f in files
                    if path.extname(f) is ".json"
                        basename = path.basename f, ".json"
                        filename = path.resolve __dirname, "../data", f

                        try
                            contents = fs.readFileSync filename, "utf8"
                            @[basename] = utils.data.minifyJson contents
                            logger.info "AppData.init", f
                        catch ex
                            logger.error "AppData.init", "Could not load #{f}", ex

                resolve()

# Singleton implementation.
# -----------------------------------------------------------------------------
AppData.getInstance = ->
    @instance = new AppData() if not @instance?
    return @instance

module.exports = exports = AppData.getInstance()
