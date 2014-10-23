# SERVER: MANAGER
# -----------------------------------------------------------------------------
# Wrapper for all managers. A "manager" is responsible for automated actions
# based on data processed by relevant API modules.
class Manager

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    commander = require "./commander.coffee"
    fs = require "fs"
    jsonPath = require "./jsonpath.coffee"
    lodash = expresser.libs.lodash
    path = require "path"

    # Modules will be populated on init.
    modules: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init Ayla API.
    init: (callback) =>
        rootPath = path.join __dirname, "../"
        managerPath = rootPath + "server/manager/"

        # Init the commander.
        commander.init()

        # Init modules.
        files = fs.readdirSync managerPath
        for f in files
            if f.indexOf("basemanager.coffee") < 0 and f.indexOf(".coffee") > 0
                module = require "./manager/#{f}"
                module.init()
                @modules[module.moduleNameLower] = module

        # Start all managers.
        m.start() for k, m of @modules

        # Proceed with callback?
        callback() if callback?

    # Dispatch settings and modules info to clients.
    emitSockets: =>
        sockets.emit "server.settings", settings
        sockets.emit "server.manager", @modules

# Singleton implementation.
# -----------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()
