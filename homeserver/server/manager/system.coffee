# SERVER: SYSTEM MANAGER
# -----------------------------------------------------------------------------
# Handles the Ayla server, dependencies and resources.
class SystemManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    cron = expresser.cron
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings
    utils = expresser.utils

    title: "System"
    icon: "fa-cogs"

    # Server status will be updated every minute.
    timerServerInfo = null
    timerJobs = null

    # INIT
    # -------------------------------------------------------------------------

    # Init the System manager.
    init: =>
        @defaultUser = lodash.find settings.users, {isDefault: true}

        @baseInit()

    # Start the System manager and listen to data updates / events.
    start: =>
        @getServerStatus()
        @getJobs()

        timerServerInfo = setInterval @getServerStatus, 60001
        timerJobs = setInterval @getJobs, 60002

        @baseStart()

    # Stop the System manager.
    stop: =>
        clearInterval timerServerInfo
        clearInterval timerJobs

        timerServerInfo = null
        timerJobs = null

        @baseStop()

    # SERVER GENERAL INFO
    # -------------------------------------------------------------------------

    # Get current server status (CPU, memory etc).
    getServerStatus: =>
        @data.server = utils.getServerInfo()
        @dataUpdated "server"

    # Get schedulded jobs.
    getJobs: =>
        @data.jobs = []

        for j in cron.jobs
            job = {id: j.id, schedule: j.schedule, nextRun: j.nextRun, endTime: j.endTime}
            @data.jobs.push job

        @dataUpdated "jobs"

# Singleton implementation.
# -----------------------------------------------------------------------------
SystemManager.getInstance = ->
    @instance = new SystemManager() if not @instance?
    return @instance

module.exports = exports = SystemManager.getInstance()
