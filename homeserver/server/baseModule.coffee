# AYLA BASE MODULE
# -----------------------------------------------------------------------------
# This contains basic features for data and logging. Used by API Modules and Managers.
class BaseModule

    expresser = require "expresser"
    cron = expresser.cron
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Called when the module inits.
    baseInit: (initialData) =>
        @moduleName = @__proto__.constructor.name.toString()
        @moduleId = @moduleName.toLowerCase()

        # Create initial data or an empty object if none was passed.
        initialData = {} if not initialData?
        @data = initialData if not @data?

        # Create module controlling and health objects.
        @errors = {}
        @timers = {}
        @notifications = {}
        @running = false

        # Log and start.
        logger.debug "#{@moduleName}.init"
        @start()

    # Called when the module starts.
    baseStart: =>
        @running = true

        # Start cron jobs for that module.
        cron.start {module: "#{@moduleId}.coffee"}

    # Called when the module stops.
    baseStop: =>
        @running = false

        # Stop cron jobs for that module.
        cron.stop {module: "#{@moduleId}.coffee"}

    # DATA HANDLING
    # -------------------------------------------------------------------------

    # Load data from the database and populate the `data` property.
    loadData: =>
        database.get "data-#{@moduleId}", (err, results) =>
            if err?
                logger.error "#{@moduleName}.loadData", err
            else
                logger.info "#{@moduleName}.loadData", "#{results.length} objects to be loaded."

            # Iterate results.
            for r in results
                @data[r.key] = r.data

            # Trigger load event.
            events.emit "#{@moduleId}.data.load"

    # Save module's data for the specified key. The filter is optional and
    # if not passed it will use `default` as filter.
    setData: (key, value, filter) =>
        filter = "default" if not filter?

        events.emit "#{@moduleId}.data", key, value, filter
        events.emit "#{@moduleId}.data.#{key}", value, filter
        sockets.emit "#{@moduleId}.data", key, value, filter
        sockets.emit "#{@moduleId}.data.#{key}", value, filter

        # Set data and cleanup old.
        @data[key] = [] if not @data[key]?
        @data[key].push {value: value, filter: filter, timestamp: moment().unix()}
        @data[key].shift() if @data[key].length > settings.modules.dataKeyCacheSize

        # Save the new data to the database.
        dbData = {key: key, value: value, filter: filter, datestamp: new Date()}

        database.set "data-#{@moduleId}", dbData, (err, result) =>
            if err?
                logger.error "#{@moduleName}.setData", key, err
            else
                logger.debug "#{@moduleName}.setData", key, value

    # LOGGING AND ERRORS
    # -------------------------------------------------------------------------

    # Log when a module is called when not running (mainly because of missing settings).
    logNotRunning: (methodName) =>
        logger.warn "#{moduleName}.notRunning", methodName
        return false

    # Logs module errors.
    logError: =>
        id = arguments[0]
        args = lodash.toArray arguments

        # Append to the errors log.
        @errors[id] = [] if not @errors[id]?
        @errors[id].push {timestamp: moment().unix(), data: args}
        count = @errors[id].length

        # Too many consecutive errors? Stop the module.
        if count is settings.general.stopOnErrorCount
            logger.critical id, "Too many consecutive errors (#{count}) logged.", "Module will now stop."
            @stop()

        logger.error.apply logger, args

    # Helper to clear old errors.
    clearErrors: =>
        maxAge = moment().subtract("h", settings.general.errorMaxAgeHours).unix()

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