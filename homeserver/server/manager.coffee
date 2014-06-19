# SERVER: MANAGER
# -----------------------------------------------------------------------------
# Wrapper for all managers. A "manager" is responsible for automated actions
# based on data processed by relevant API modules.
class Manager

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

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

        # Init modules.
        files = fs.readdirSync managerPath
        for f in files
            if f isnt "basemanager.coffee" and f.indexOf(".coffee") > 0
                module = require "./manager/#{f}"
                module.init()
                @modules[module.moduleId] = module

        # Start the rules engine, but only if enabled on settings.
        @startRules() if settings.rules.enabled

        # Proceed with callback?
        callback() if callback?

    # RULES ENGINE
    # -------------------------------------------------------------------------

    # Start the rules engine by parsing the rules.json file.
    startRules: =>
        @rules = require "../rules.json"

        if not @rules
            logger.warn "Manager.startRules", "File rules.json not found or invalid."

        setInterval @processRules, settings.rules.interval

    # Process all custom rules. This runs every minute by default.
    processRules: =>
        for rule in @rules
            m = @modules[rule.manager + "manager"]

            # Check if module is valid and enabled.
            if not m?
                logger.warn "Manager.processRules", "Module is disable, abort processing current rule.", rule
            else
                d = jsonPath m.data, rule.data

                # Evaluate rule only if data is present.
                if d?
                    active = false

                    if rule.condition is ">" and d > rule.value
                        active = true
                    else if rule.condition is "<" and d < rule.value
                        active = true
                    else if rule.condition is "=" and d is rule.value
                        active = true
                    else if rule.condition is "!=" and d isnt rule.value
                        active = true

                    # Is rule active? Trigger its actions!
                    if active
                        for actionKey, actionParams of rule.action
                            @ruleAction_Command rule, d, actionParams if actionKey is "command"
                            @ruleAction_Email rule, d, actionParams if actionKey is "email"

    # Execute a predefined command using the Commander.
    ruleAction_Command: (rule, data, params) =>
        logger.info "Manager.ruleAction_Command", rule, data, params

    # Send email.
    ruleAction_Email: (rule, data, params) =>
        logger.info "Manager.ruleAction_Email", rule, data, params

# Singleton implementation.
# -----------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()