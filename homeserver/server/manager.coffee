# SERVER: MANAGER
# -----------------------------------------------------------------------------
# Wrapper for all managers. A "manager" is responsible for automated actions
# based on data processed by API modules.
class Manager

    expresser = require "expresser"

    commander = require "./commander.coffee"
    events = expresser.events
    fs = require "fs"
    jsonPath = require "./jsonpath.coffee"
    lodash = expresser.libs.lodash
    logger = expresser.logger
    path = require "path"
    settings = expresser.settings
    sockets = expresser.sockets

    # Modules will be set on init.
    modules: {}
    disabledModules: {}

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
            if f isnt "basemanager.coffee" and f.indexOf(".coffee") > 0
                filename = f.replace ".coffee", ""
                enabled = lodash.indexOf(settings.modules.managers, filename) >= 0

                # Only add if set on enabled managers setting.
                if not enabled
                    logger.debug "Manager.init", f, "Manager is not enabled and won't be instantiated."
                    @disabledModules[filename] = filename
                else
                    module = require "./manager/#{f}"
                    module.init()
                    @modules[filename] = module

        # Start all managers.
        m.start() for k, m of @modules

        # Proceed with callback?
        callback() if callback?

    # Stop all managers and clear timers.
    stop: (callback) =>
        m.stop() for k, m of @modules

        callback() if callback?

# Singleton implementation.
# -----------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()
