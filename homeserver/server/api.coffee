# SERVER: API
# -----------------------------------------------------------------------------
# Wrapper for all server API modules. Each API module is responsible for getting
# and sending data to a specific service or device, and interacting with
# relevant managers (see manager.coffee).
class Api

    expresser = require "expresser"
    cron = expresser.cron
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    fs = require "fs"
    lodash = expresser.libs.lodash
    path = require "path"

    # Modules and timers will be set on init.
    modules: {}
    disabledModules: {}
    timers: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init all API modules.
    init: (callback) =>
        rootPath = path.join __dirname, "../"
        cronPath = rootPath + "cron.api.json"
        apiPath = rootPath + "server/api/"

        # Init modules.
        files = fs.readdirSync apiPath

        for f in files
            if f isnt "baseapi.coffee" and f.indexOf(".coffee") > 0
                filename = f.replace ".coffee", ""
                enabled = lodash.contains settings.modules.enable, filename

                # Only add if not on the disabled modules setting.
                if not enabled
                    logger.debug "Api.init", f, "Module is not enabled and won't be instantiated."
                    @disabledModules[filename] = filename
                else
                    module = require "./api/#{f}"
                    module.init()
                    @modules[module.moduleNameLower] = module

                    # Create database TTL index.
                    expires = settings.database.dataCacheExpireHours * 3600
                    database.db.collection("data-#{module.dbName}").ensureIndex {"datestamp": 1}, {expireAfterSeconds: expires}, (err) -> console.error err if err?

        # Start all API modules and load cron jobs.
        m.start() for k, m of @modules
        cron.load cronPath, {basePath: apiPath} if settings.cron.enabled

        # Emit modules data to clients every few minutes.
        @emitModules()
        @timers["modules"] = setInterval @emitModules, settings.modules.socketsEmitIntervalMinutes

        # Proceed with callback?
        callback() if callback?

    # Stop all API modules and clear timers.
    stop: (callback) =>
        for k, m of @modules
            m.stop()

        for k, t of @timers
            clearInterval @timers[k]
            delete timers[k]

        callback() if callback?

    # Dispatch modules info to clients.
    emitModules: =>
        sockets.emit "server.api.modules", @modules, @disabledModules

# Singleton implementation.
# -----------------------------------------------------------------------------
Api.getInstance = ->
    @instance = new Api() if not @instance?
    return @instance

module.exports = exports = Api.getInstance()
