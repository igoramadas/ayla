# SERVER: MANAGER
# -----------------------------------------------------------------------------
# Wrapper for all managers. A "manager" is responsible for automated actions
# based on data processed by relevant API modules.
class Manager

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    fs = require "fs"
    jsonPath = require "./jsonPath.coffee"
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

        # Init modules.
        files = fs.readdirSync managerPath
        for f in files
            if f isnt "baseManager.coffee" and f.indexOf(".coffee") > 0
                module = require "./manager/#{f}"
                module.init()
                @modules[module.moduleId] = module

        # Start the rules engine.
        @startRules()

        # Proceed with callback?
        callback() if callback?

    # RULE ENGINE
    # -------------------------------------------------------------------------

    # Start the rules engine.
    startRules: =>
        @rules = require "../rules.json"

        setInterval @processRules, 5000

    # Process all custom rules by the user.
    processRules: =>
        lodash.each @rules, (rule) =>
            m = @modules[rule.manager + "manager"]

            # Check if module is valid and enabled.
            if not m?
                logger.warn "Manager.processRules", "Module is disable, abort processing current rule.", rule
                return

            d = jsonPath m.data, rule.data
            console.warn d


# Singleton implementation.
# -----------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()