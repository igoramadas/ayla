# SERVER: DATA
# -----------------------------------------------------------------------------
# Handles all data from the /data folder as JSON objects.
class Data

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    fs = require "fs"
    path = require "path"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # The cache will be set on `load` as key / data.
    cache: {}

    # INIT AND LOADING
    # -------------------------------------------------------------------------

    # Init the Data module.
    init: =>
        @load()

    # Load all .json files from the /data folder. Each file will be transformed
    # and set as a local property inside the `cache` property.
    load: =>
        @cache = {}

        dirname = path.join __dirname, "../", settings.path.data

        # Read files from /data.
        fs.readdir dirname, (err, files) =>
            if err?
                logger.error "Data.load", dirname, err
            else
                logger.debug "Data.load", dirname, "#{files.length} files."

            # Iterate all files but process only JSON files.
            for f in files
                if path.extname(f) is ".json"
                    key = path.basename f, ".json"
                    @cache[key] = require dirname + f

    # SAVING
    # -------------------------------------------------------------------------

    # Save the specified JSON object to the disk.
    saveToDisk: (key, data) =>
        console.warn data

    # Save the specified JSON object to the database.
    saveToDb: (key, data) ->
        console.warn data


# Singleton implementation.
# -----------------------------------------------------------------------------
Data.getInstance = ->
    @instance = new Data() if not @instance?
    return @instance

module.exports = exports = Data.getInstance()