# AYLA BASE MODULE
# -----------------------------------------------------------------------------
# This contains basic features for data and logging. Used by API Modules and Managers.
class BaseModule

    expresser = require "expresser"
    cron = null
    events = null
    lodash = null
    logger = null
    moment = null
    settings = null
    sockets = null

    # INIT
    # -------------------------------------------------------------------------

    # Called when the module inits.
    baseInit: (initialData) =>
        cron = expresser.cron
        events = expresser.events
        lodash = expresser.libs.lodash
        logger = expresser.logger
        moment = expresser.libs.moment
        settings = expresser.settings
        sockets = expresser.sockets

        @errors = {}

        @moduleName = @__proto__.constructor.name.toString()
        @moduleNameLower = @moduleName.toLowerCase()
        @initTimestamp = moment().unix()

        # Create initial data or an empty object if none was passed.
        initialData = {} if not initialData?
        @data = initialData if not @data?
        expresser.datastore[@moduleName] = @data

        # Create module controlling and health objects.
        @timers = {}
        @notifications = {}
        @routes = []
        @running = false
        @initialDataLoaded = false

        logger.debug "#{@moduleName}.baseInit"

    # Called when the module starts.
    baseStart: =>
        @running = true
        logger.info "#{@moduleName}.baseStart"

        # Start cron jobs for that module.
        cron.start {module: "#{@moduleName}.coffee"} if settings.cron.enabled and @hasCron

    # Called when the module stops.
    baseStop: =>
        @running = false
        logger.info "#{@moduleName}.baseStop"

        # Stop cron jobs for that module.
        cron.stop {module: "#{@moduleName}.coffee"} if settings.cron.enabled and @hasCron

    # DATA HANDLING
    # -------------------------------------------------------------------------

    # Save module's data for the specified key. The filter is optional and
    # if not passed it will use `default` as filter.
    setData: (key, value, filter) =>
        filter = "default" if not filter?

        try
            dataObj = {value: value, filter: filter, timestamp: moment().unix()}
            @data[key] = [] if not @data[key]?
            @data[key].unshift dataObj
            @data[key].pop() if @data[key].length > settings.modules.dataKeyCacheSize

            # Emit events to other modules and clients.
            events.emit "#{@moduleName}.data", key, dataObj, filter
            sockets.emit "#{@moduleName}.data", key, dataObj, filter

        catch ex
            @logError "#{@moduleName}.setData", key, ex.message, ex.stack

    # LOGGING AND ERRORS
    # -------------------------------------------------------------------------

    # Log when a module is called when not running (mainly because of missing settings).
    logNotRunning: (methodName) =>
        logger.warn "#{@moduleName}.notRunning", methodName
        return false

    # Logs module errors.
    logError: =>
        id = arguments[0]
        args = lodash.toArray arguments

        # Append to the errors log.
        @errors[id] = [] if not @errors[id]?
        @errors[id].push {timestamp: moment().unix(), data: args}
        count = @errors[id].length

        logger.error.apply logger, args

        # Too many consecutive errors? Stop the module.
        if count is settings.general.stopOnErrorCount
            logger.critical id, "Too many consecutive errors (#{count}) logged.", "Module will now stop."
            @stop()

    # Helper to clear old errors.
    clearErrors: =>
        maxAge = moment().subtract(settings.general.errorMaxAgeHours, "h").unix()

        # Iterate errors by ID, then internal data, and remove everything which is too old.
        for key, value of @errors
            for d in value
                if d.timestamp < maxAge
                    lodash.remove value, d
            if value.length < 1
                delete @errors[key]

# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseModule
