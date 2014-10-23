# SERVER: MANAGER
# -----------------------------------------------------------------------------
# Wrapper for all managers. A "manager" is responsible for automated actions
# based on data processed by API modules.
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

    # Modules and timers will be set on init.
    modules: {}
    timers: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init all managers.
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

        # Emit settings and modules data to clients every few minutes.
        @emitSettings()
        @emitModules()
        @timers["settings"] = setInterval @emitSettings, settings.modules.socketsEmitIntervalMinutes
        @timers["modules"] = setInterval @emitModules, settings.modules.socketsEmitIntervalMinutes

        # Proceed with callback?
        callback() if callback?

    # Stop all managers and clear timers.
    stop: (callback) =>
        for k, m of @modules
            m.stop()

        for k, t of @timers
            clearInterval @timers[k]
            delete timers[k]

        callback() if callback?

    # Dispatch settings to clients.
    emitSettings: =>
        sockets.emit "server.settings", settings

    # Dispatch modules to clients.
    emitModules: =>
        sockets.emit "server.manager.modules", @modules

# Singleton implementation.
# -----------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()
