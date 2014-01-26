# SERVER: MANAGER
# -----------------------------------------------------------------------------
# Wrapper for all managers. A "manager" is responsible for automated actions
# based on data processed by relevant API modules.
class Manager

    expresser = require "expresser"
    logger = expresser.logger
    mailer = expresser.mailer
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
        managerPath = rootPath + "server/manager/"

        # Init modules.
        files = fs.readdirSync managerPath

        for f in files
            if f isnt "baseManager.coffee" and f.indexOf(".coffee") > 0
                module = require "./manager/#{f}"
                module.init()
                @modules[module.moduleId] = module

        # Send email telling Ayla home server has started.
        mailer.send {to: settings.email.toMobile, subject: "Ayla home server started!", body: "Hi there, sir."}

        # Proceed with callback?
        callback() if callback?

# Singleton implementation.
# -----------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()