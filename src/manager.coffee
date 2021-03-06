# SERVER: MANAGER
# -----------------------------------------------------------------------------
# Wrapper for all managers. A "manager" is responsible for automated actions
# based on data processed by API modules.
class Manager

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

    # Init all managers.
    init: =>
        return new Promise (resolve, reject) =>
            rootPath = path.join __dirname, "../"
            managerPath = rootPath + "src/manager/"

            # Init modules.
            files = fs.readdirSync managerPath
            for f in files
                try
                    if f isnt "basemanager.coffee" and f.indexOf(".coffee") > 0
                        filename = f.replace ".coffee", ""

                        module = require "./manager/#{f}"
                        module.init()
                        @modules[filename] = module

                        logger.info "Manager.init", filename, "Loaded"
                catch ex
                    logger.error "Manager.init", "Error loading module", f, ex
                    return reject ex

            # Start all managers.
            try
                m.start() for k, m of @modules
            catch ex
                logger.error "Manager.init", "Error starting modules", ex
                return reject ex

            resolve()

    # Stop all managers and clear timers.
    stop: (callback) =>
        m.stop() for k, m of @modules

        callback?()

# Singleton implementation.
# -----------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()
