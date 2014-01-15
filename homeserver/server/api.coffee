# SERVER: API
# -----------------------------------------------------------------------------
# Wrapper for all server API modules. An "api" is responsible for getting
# and sending data from / to a specific online service.
class Api

    expresser = require "expresser"
    cron = expresser.cron
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    fs = require "fs"
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
            if f isnt "baseApi.coffee" and f.indexOf(".coffee") > 0
                module = require "./api/#{f}"
                module.init()
                @modules[module.moduleId] = module

        # Load cron jobs.
        cron.load cronPath, {basePath: apiPath}

        # Proceed with callback?
        callback() if callback?


# Singleton implementation.
# -----------------------------------------------------------------------------
Api.getInstance = ->
    @instance = new Api() if not @instance?
    return @instance

module.exports = exports = Api.getInstance()