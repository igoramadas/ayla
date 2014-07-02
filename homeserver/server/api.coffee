# SERVER: API
# -----------------------------------------------------------------------------
# Wrapper for all server API modules. An "api" is responsible for getting
# and sending data from / to a specific online service.
class Api

    expresser = require "expresser"
    cron = expresser.cron
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    fs = require "fs"
    lodash = expresser.libs.lodash
    path = require "path"

    # Modules will be populated on init.
    modules: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init Ayla API.
    init: (callback) =>
        rootPath = path.join __dirname, "../"
        cronPath = rootPath + "cron.api.json"
        apiPath = rootPath + "server/api/"

        # Init modules.
        files = fs.readdirSync apiPath

        for f in files
            if f isnt "baseapi.coffee" and f.indexOf(".coffee") > 0
                enabled = lodash.contains settings.modules.enable, f.replace(".coffee", "")

                # Only add if not on the disabled modules setting.
                if not enabled
                    logger.debug "Api.init", f, "Module is not enabled and won't be instantiated."
                else
                    module = require "./api/#{f}"
                    module.init()
                    @modules[module.moduleId] = module

                    # Create database TTL index.
                    expires = settings.database.dataCacheExpireHours * 3600
                    database.db.collection("data-#{module.moduleId}").ensureIndex {"datestamp": 1}, {expireAfterSeconds: expires}, (err) -> console.error err if err?

        # Start all API modules and load cron jobs.
        m.start() for k, m of @modules
        cron.load cronPath, {basePath: apiPath}

        # Proceed with callback?
        callback() if callback?


# Singleton implementation.
# -----------------------------------------------------------------------------
Api.getInstance = ->
    @instance = new Api() if not @instance?
    return @instance

module.exports = exports = Api.getInstance()