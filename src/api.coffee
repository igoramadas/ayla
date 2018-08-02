# SERVER: API
# -----------------------------------------------------------------------------
# Wrapper for all server API modules. Each API module is responsible for getting
# and sending data to a specific service or device, and interacting with
# relevant managers (see manager.coffee).
class Api

    expresser = require "expresser"
    lodash = expresser.libs.lodash
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    fs = require "fs"
    path = require "path"

    # Modules will be set on init.
    modules: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init all API modules.
    init: (callback) =>
        cron = expresser.cron

        rootPath = path.join __dirname, "../"
        cronPath = rootPath + "cron.api.json"
        apiPath = rootPath + "server/api/"

        # Make sure oauth data path exists.
        oauthPath = path.join __dirname, "../data/oauth/"
        utils.io.mkdirRecursive oauthPath

        # Init modules.
        files = fs.readdirSync apiPath

        for f in files
            if f isnt "baseapi.coffee" and f.indexOf(".coffee") > 0
                filename = f.replace ".coffee", ""

                apiSettingsPath = __dirname + "/api/" + f.replace ".coffee", ".settings.json"
                settings.loadFromJson apiSettingsPath

                module = require "./api/#{f}"
                module.init()
                @modules[filename] = module

                logger.info "Api.init", filename, "Loaded"

        # Start all API modules and load cron jobs.
        m.start() for k, m of @modules
        cron.load cronPath, {basePath: "server/api/"} if settings.cron.enabled

        callback?()

    # Stop all API modules and clear timers.
    stop: (callback) =>
        m.stop() for k, m of @modules

        callback?()

# Singleton implementation.
# -----------------------------------------------------------------------------
Api.getInstance = ->
    @instance = new Api() if not @instance?
    return @instance

module.exports = exports = Api.getInstance()
