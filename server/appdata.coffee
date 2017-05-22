# SERVER: APPDATA
# -----------------------------------------------------------------------------
# Central module that holds general app data.
class AppData

    expresser = require "expresser"
    utils = expresser.utils
    fs = require "fs"
    path = require "path"

    # INIT
    # -------------------------------------------------------------------------

    # Load initial data from the /data folder.
    init: (callback) =>
        dataPath = path.resolve __dirname, "../data"
        fs.readdir dataPath, (err, files) =>
            if err?

            else
                for f in files
                    if path.extname(f) is ".json"
                        basename = path.basename f, ".json"
                        filename = path.resolve __dirname, "../data", f

                        try
                            contents = fs.readFileSync filename, "utf8"
                            @[basename] = utils.data.minifyJson contents
                        catch ex
                            logger.error "AppData.init", "Could not load #{f}", ex

            callback() if callback?

# Singleton implementation.
# -----------------------------------------------------------------------------
AppData.getInstance = ->
    @instance = new AppData() if not @instance?
    return @instance

module.exports = exports = AppData.getInstance()
