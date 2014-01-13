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

    # The static cache will set on `load` as key / data.
    static: {}

    # INIT AND LOADING
    # -------------------------------------------------------------------------

    # Init the Data module.
    init: =>
        @basePath = path.join __dirname, "../", settings.path.data

        # Iterate API files to add to the `modules` array.
        apiFiles = fs.readdirSync __dirname + "/api"
        for f in apiFiles
            @modules.push f.replace(".coffee", "") if f isnt "baseApi.coffee"

        # Load static data and set jobs.
        @loadStatic()

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


# Singleton implementation.
# -----------------------------------------------------------------------------
Data.getInstance = ->
    @instance = new Data() if not @instance?
    return @instance

module.exports = exports = Data.getInstance()