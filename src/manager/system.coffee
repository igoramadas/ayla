# SERVER: SYSTEM MANAGER
# -----------------------------------------------------------------------------
# Handles the Ayla server, dependencies and resources.
class SystemManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    api = require "../api.coffee"
    cron = expresser.plugins.cron
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings
    utils = expresser.utils

    title: "System"
    icon: "fa-cogs"

    # Timers to emit data to clients.
    timers: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the System manager.
    init: =>
        @defaultUser = lodash.find settings.users, {isDefault: true}

        @baseInit()

    # Start the System manager and listen to data updates / events.
    start: =>
        @getApiModules()
        @getJobs()
        @getServerInfo()
        @getSettings()

        @timers["apimodules"] = setInterval @getApiModules, 90000
        @timers["jobs"] = setInterval @getJobs, 30000
        @timers["serverinfo"] = setInterval @getServerInfo, 10000
        @timers["settings"] = setInterval @getSettings, 30000

        @baseStart()

    # Stop the System manager.
    stop: =>
        for k, t of @timers
            clearInterval @timers[k]
            delete @timers[k]

        @baseStop()

    # SERVER GENERAL INFO
    # -------------------------------------------------------------------------

    # Get API modules information.
    getApiModules: =>
        modules = []
        modules.push(getModuleInfo m) for k, m of api.modules
        disabledModules = api.disabledModules

        @data.apiModules = modules

        @data.disabledModules = disabledModules

    # Get scheduled jobs.
    getJobs: =>
        @data.jobs = []

        for j in cron.jobs
            job = {id: j.id, schedule: j.schedule, nextRun: j.nextRun, endTime: j.endTime}
            @data.jobs.push job

        @dataUpdated "jobs"

    # Get current server status (CPU, memory etc).
    getServerInfo: =>
        @data.server = utils.system.getInfo()
        @dataUpdated "server"

    # Get current server settings. Clean settings before sending to clients.
    getSettings: =>
        result = lodash.cloneDeep settings

        cleanSettings = (obj, level) ->
            for key, value of obj
                if lodash.isFunction value
                    delete obj[key]
                else if level < 3 and lodash.isObject value
                    cleanSettings obj, level + 1

        cleanSettings result, 0

        @data.settings = result
        @dataUpdated "settings"

    # HELPERS
    # -------------------------------------------------------------------------

    # Helper to get relevant module info to be sent to clients.
    # Return as string.
    getModuleInfo = (module) ->
        result = {methods: []}

        # Iterate module to get its properties. Functions will be merged
        # onto the `methods` property.
        for prop in lodash.keys module
            v = module[prop]

            if lodash.isFunction(v)
                result.methods.push prop
            else if prop is "oauth"
                result.oauth = {authenticated: v.authenticated, data: v.data}
            else
                result[prop] = v

        # Set OAuth as false if it doesn't exist.
        result.oauth = false if not result.oauth?

        return result

# Singleton implementation.
# -----------------------------------------------------------------------------
SystemManager.getInstance = ->
    @instance = new SystemManager() if not @instance?
    return @instance

module.exports = exports = SystemManager.getInstance()
