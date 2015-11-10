# SERVER: API
# -----------------------------------------------------------------------------
# Wrapper for all server API modules. Each API module is responsible for getting
# and sending data to a specific service or device, and interacting with
# relevant managers (see manager.coffee).
class Api

    expresser = require "expresser"
    database = null
    events = null
    lodash = null
    logger = null
    settings = null
    sockets = null

    fs = require "fs"
    path = require "path"

    # Modules will be set on init.
    modules: {}
    disabledModules: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init all API modules.
    init: (callback) =>
        cron = expresser.cron
        database = expresser.database
        events = expresser.events
        lodash = expresser.libs.lodash
        logger = expresser.logger
        settings = expresser.settings
        sockets = expresser.sockets

        rootPath = path.join __dirname, "../"
        cronPath = rootPath + "cron.api.json"
        apiPath = rootPath + "server/api/"

        # Init modules.
        files = fs.readdirSync apiPath

        for f in files
            if f isnt "baseapi.coffee" and f.indexOf(".coffee") > 0
                filename = f.replace ".coffee", ""
                enabled = lodash.contains settings.modules.api, filename

                # Only add if set on enabled modules setting.
                if not enabled
                    logger.debug "Api.init", f, "API Module is not enabled and won't be instantiated."
                    @disabledModules[filename] = filename
                else
                    module = require "./api/#{f}"
                    module.init()
                    @modules[filename] = module

                    # Create database TTL index.
                    expires = settings.database.mongo.dataCacheExpireHours * 3600
                    database.db.mongo.connection.collection("data-#{module.dbName}").ensureIndex {"datestamp": 1}, {expireAfterSeconds: expires}, (err) -> console.error err if err?

        # Start all API modules and load cron jobs.
        m.start() for k, m of @modules
        cron.load cronPath, {basePath: "server/api/"} if settings.cron.enabled

        # Proceed with callback?
        callback() if callback?

    # Stop all API modules and clear timers.
    stop: (callback) =>
        m.stop() for k, m of @modules

        callback() if callback?

# Singleton implementation.
# -----------------------------------------------------------------------------
Api.getInstance = ->
    @instance = new Api() if not @instance?
    return @instance

module.exports = exports = Api.getInstance()
