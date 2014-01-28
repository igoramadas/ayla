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

    # User actions will be populated on init.
    userActions: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init Ayla API.
    init: (callback) =>
        rootPath = path.join __dirname, "../"
        managerPath = rootPath + "server/manager/"
        userActionsPath = rootPath + "server/userActions/"

        # Init modules.
        files = fs.readdirSync managerPath
        for f in files
            if f isnt "baseManager.coffee" and f.indexOf(".coffee") > 0
                module = require "./manager/#{f}"
                module.init()
                @modules[module.moduleId] = module

        # Init user actions.
        files = fs.readdirSync userActionsPath
        for f in files
            if f.indexOf(".coffee") > 0
                userAction = require "./userActions/#{f}"
                @modules[path.basename(f, ".coffee")] = userAction

        # Send email telling Ayla home server has started.
        if settings.email?.toMobile?
            mailer.send {to: settings.email.toMobile, subject: "Ayla home server started!", body: "Hi there, sir."}
        else
            logger.warn "Manager.init", "Mailer settings are not defined. Start email won't be sent out."

        # Proceed with callback?
        callback() if callback?


# Singleton implementation.
# -----------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()