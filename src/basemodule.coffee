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
            logger.error "#{@moduleName}.setData", key, ex.message, ex.stack

# Exports API Base Module.
# -----------------------------------------------------------------------------
module.exports = exports = BaseModule
