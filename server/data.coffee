# SERVER: DATA
# -----------------------------------------------------------------------------
# Handles all data from the /data folder as JSON objects.
class Data

    expresser = require "expresser"
    events = expresser.events
    cron = expresser.cron
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings

    fs = require "fs"
    lodash = require "lodash"
    moment = require "moment"
    path = require "path"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # The base path to the /data folder.
    basePath: null

    # The static data and main cache will be set on `load` as key / data.
    static: {}
    cache: {}

    # INIT AND LOADING
    # -------------------------------------------------------------------------

    # Init the Data module.
    init: =>
        @basePath = path.join __dirname, "../", settings.path.data
        @loadStatic()
        @loadCache()
        @setJobs()

    # Load all .json files from the /data folder. Each file will be transformed
    # and set as a local property inside the `static` property.
    loadStatic: =>
        @static = {}

        # Read files from the data folder.
        fs.readdir @basePath, (err, files) =>
            if err?
                logger.error "Data.loadStatic", @basePath, err
            else
                logger.info "Data.loadStatic", @basePath, "#{files.length} files to be loaded."

            # Iterate all files but process only JSON files.
            for f in files
                if path.extname(f) is ".json"
                    key = path.basename f, ".json"
                    @static[key] = require @basePath + f

            # Trigger loaded event.
            events.emit "data.static.load", @static

    # Load data from the database and populate the `cache` property.
    loadCache: =>
        database.get "data-cache", (err, results) =>
            if err?
                logger.error "Data.loadCache", err
            else
                logger.info "Data.loadCache", "#{results.length} objects to be loaded."

            # Iterate results
            for r in results
                @cache[r.key] = @cache[r.data]

            # Trigger loaded event.
            events.emit "data.cache.load"

    # ADDING AND SAVING
    # -------------------------------------------------------------------------

    # Add or update data to the disk.
    upsert: (key, data, options) =>
        logger.debug "Data.upsert", key, data

        # Set default options to archive to DB and save to disk.
        options = {} if not options?
        options = lodash.defaults options, {saveToDatabase: true}

        # If data is already cached, check if it should be saved to the DB before updating.
        if @cache[key]? and options.saveToDatabase
            @saveToDatabase key, @cache[key]

        # Set new data.
        @cache[key] = data

    # Save data to the MongoDB database.
    saveToDatabase: (key, data) =>
        obj = {key: key, data: data}

        database.set "data-cache", obj, (err, result) =>
            if err?
                logger.error "Data.saveToDatabase", key, err
            else
                logger.debug "Data.saveToDatabase", key, data

    # MAINTENANCE
    # -------------------------------------------------------------------------

    # Create maintenance jobs.
    setJobs: =>
        cron.add {id: "data.cleanOld", schedule: ["00:00:05"], callback: @cleanOld}

    # Remove old data from the MongoDB database.
    cleanOld: =>
        database.del()


# Singleton implementation.
# -----------------------------------------------------------------------------
Data.getInstance = ->
    @instance = new Data() if not @instance?
    return @instance

module.exports = exports = Data.getInstance()