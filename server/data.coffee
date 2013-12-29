# SERVER: DATA
# -----------------------------------------------------------------------------
# Handles all data from the /data folder as JSON objects.
class Data

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    fs = require "fs"
    lodash = require "lodash"
    path = require "path"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # The base path to the data folder.
    basePath: null

    # The cache will be set on `load` as key / data.
    cache: {}

    # INIT AND LOADING
    # -------------------------------------------------------------------------

    # Init the Data module.
    init: =>
        @basePath = path.join __dirname, "../", settings.path.data
        @load()

    # Load all .json files from the /data folder. Each file will be transformed
    # and set as a local property inside the `cache` property.
    load: =>
        @cache = {}

        # Read files from the data folder.
        fs.readdir @basePath, (err, files) =>
            if err?
                logger.error "Data.load", @basePath, err
            else
                logger.info "Data.load", @basePath, "#{files.length} files."

            # Iterate all files but process only JSON files.
            for f in files
                if path.extname(f) is ".json"
                    key = path.basename f, ".json"
                    @cache[key] = require @basePath + f

    # ADDING AND SAVING
    # -------------------------------------------------------------------------

    # Add or update data to the cache.
    upsert: (key, data, options) =>
        logger.debug "Data.upsert", key, data

        # Set default options to archive to DB and save to disk.
        options = {} if not options?
        options = lodash.defaults options, {saveToDb: false, archiveToDb: true, saveToDisk: true}

        # If data is already cached, check if it should be saved to the DB before updating.
        if @cache[key]? and options.archiveToDb
            @saveToDb key, @cache[key]

        # Set new data.
        @cache[key] = data

        # Save to disk unless `saveToDisk` option is false.
        if options.saveToDisk
            @saveToDisk key, data

    # Save the specified JSON object to the disk.
    saveToDisk: (key, data) =>
        logger.debug "Data.saveToDisk", key, data

        # Make sure data is a string.
        data = JSON.stringify data, null, 4 if lodash.isObject data

        # Write data to the local disk.
        fs.writeFile @basePath + key + ".json", data, {encoding: settings.general.encoding}, (err, callback) =>
            if err?
                logger.error "Data.saveToDisk", key, data, err

    # Save the specified JSON object to the database.
    saveToDb: (key, data) ->
        logger.debug "Data.saveToDb", key, data

    # MAINTENANCE
    # -------------------------------------------------------------------------

    # Remove old data from the MongoDB database.
    cleanOld: =>
        logger.info "Data.cleanOld"


# Singleton implementation.
# -----------------------------------------------------------------------------
Data.getInstance = ->
    @instance = new Data() if not @instance?
    return @instance

module.exports = exports = Data.getInstance()