# SERVER: ROUTES
# -----------------------------------------------------------------------------
# All server routes are defined here.
class Routes

    expresser = require "expresser"
    cron = expresser.cron
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings
    utils = expresser.utils

    api = require "./api.coffee"
    commander = require "./commander.coffee"
    fs = require "fs"
    manager = require "./manager.coffee"
    path = require "path"

    # INIT
    # -------------------------------------------------------------------------

    # Set most routes on init. The app (from Expresser) must be passed here.
    init: (callback) =>
        app = expresser.app.server

        # Main route.
        app.get "/", indexPage

        # Dashboard routes.
        app.get "/dashboard", dashboardPage
        app.get "/dashboard/data", dashboardDataPage

        # Commander and status routes.
        app.get "/commander/:cmd", commanderPage
        app.post "/commander/:cmd", commanderPage

        # Bind API module routes.
        app.get "/api/:id", apiPage
        app.get "/api/:id/data", apiDataPage
        app.get "/api/:id/auth", apiAuthPage
        app.get "/api/:id/auth/callback", apiAuthPage
        bindModuleRoutes m for key, m of api.modules

        # Bind manager routes.
        app.get "/manager/:id", managerPage
        app.get "/manager/:id/data", managerDataPage
        bindModuleRoutes m for key, m of manager.modules

        callback?()

    # Helper to bind module routes.
    bindModuleRoutes = (m) ->
        return if m.routes.length < 1

        app = expresser.app.server

        for route in m.routes
            method = route.method.toLowerCase()

            # Get or post? Available render types are page, json and image.
            app[method] "/#{m.moduleName}/#{route.path}", (req, res) ->
                if route.render is "json"
                    renderFn = expresser.app.renderJson
                else if route.render is "image"
                    renderFn = expresser.app.renderImage
                else
                    renderFn = renderPage

                renderFn req, res, route.callback(req), route.options

    # MAIN ROUTES
    # -------------------------------------------------------------------------

    # Main route will mostly redirect to dashboard page.
    indexPage = (req, res) ->
        res.redirect "/dashboard"

    # The main dashboard homepage.
    dashboardPage = (req, res) ->
        renderPage req, res, "dashboard", {pageTitle: "Dashboard"}

    # Data returned on the dashboard page.
    dashboardDataPage = (req, res) ->
        result = {}
        managerModules = []
        apiModules = []
        jobs = []

        # Default format for short datetime.
        shortDateFormat = "DD/MM HH:mm"

        # Helper to reduce data object.
        populateData = (src, target) ->
            for dkey, dvalue of src
                timestamp = null
                lastUpdated = "empty"

                if dvalue.timestamp?
                    timestamp = dvalue.timestamp
                else if lodash.isArray dvalue
                    timestamp = dvalue[0]?.timestamp

                if timestamp?
                    lastUpdated = moment(timestamp).format shortDateFormat

                d = {key: dkey, timestamp: timestamp, lastUpdated: lastUpdated}

                target.push d

        # Get details for managers.
        for key, m of manager.modules
            obj = {id: key, moduleName: m.moduleName, errors: m.errors, data: []}
            managerModules.push obj
            populateData m.data, obj.data

        # Get details for API modules.
        for key, m of api.modules
            oauthObj = m.oauth?.getJSON(true) or null
            obj = {id: key, moduleName: m.moduleName, errors: m.errors, data: [], jobs: [], oauth: oauthObj}
            apiModules.push obj
            populateData m.data, obj.data

        # Get cron jobs.
        for job in cron.jobs
            obj = {description: job.description, schedule: job.schedule, startTime: job.startTime, endTime: job.endTime}
            obj.callback = job.id.replace(job.module, "").replace(".", "")

            if not job.endTime? or job.endTime < 1
                obj.lastRun = "never"
            else
                obj.lastRun = moment(job.endTime).format shortDateFormat

            jobs.push obj

            # Also add jobs to list of jobs in API modules.
            aModule = lodash.find apiModules, {id: job.module.replace ".coffee", ""}
            aModule.jobs.push obj if aModule?

        # Add everything to the result.
        result.server = utils.system.getInfo()
        result.managerModules = managerModules
        result.disabledManagerModules = lodash.keys manager.disabledModules
        result.apiModules = apiModules
        result.disabledApiModules = lodash.keys api.disabledModules
        result.jobs = jobs

        expresser.app.renderJson req, res, result

     # The commander processor.
    commanderPage = (req, res) ->
        commander.execute req.params.cmd, req.body, (err, result) ->
            if err?
                sendErrorResponse req, res, "commanderPage", err
            else
                expresser.app.renderJson req, res, result

    # The API module overview page.
    apiPage = (req, res) ->
        id = req.params.id
        m = api.modules[id]

        # Check if API module is enabled and running.
        if not m?
            sendErrorResponse req, res, "apiPage", "API module not found or not active."
            return

        jobs = m.getScheduledJobs()

        fs.readFile "#{__dirname}/api/#{m.moduleNameLower}.coffee", {encoding: settings.general.encoding}, (err, data) ->
            lines = data.split "\n"
            lines.splice 0, 2
            description = ""

            # Iterate first lines of the module code to get its description.
            for i in lines
                if i.substring(0, 1) is "#"
                    description += i.replace("#", "") + "\n"
                else
                    options = {title: m.moduleName, description: description}
                    options.oauth = m.oauth if m.oauth?

                    return renderPage req, res, "api", options

    # Returns data from the API module.
    apiDataPage = (req, res) ->
        id = req.params.id
        m = api.modules[id]

        # Check if API module is enabled and running.
        if not m?
            sendErrorResponse req, res, "apiDataPage", "API module not found or not active."
            return

        # Create options object.
        options = {}
        options.settings = settings[m.moduleName]
        options.moduleName = m.moduleName
        options.data = m.data
        options.errors = m.errors
        options.oauth = m.oauth.getJSON true
        options.jobs = []

        jobs = lodash.where cron.jobs, {module: m.moduleName + ".coffee"}

        for job in jobs
            options.jobs.push {id: job.id, schedule: job.schedule, endTime: job.endTime}

        expresser.app.renderJson req, res, options

    # Handles authentication for API modules.
    apiAuthPage = (req, res) ->
        id = req.params.id
        m = api.modules[id]

        if not m?
            sendErrorResponse req, res, "apiAuthPage", "API module not found or not active."
        else if not m?.oauth?
            sendErrorResponse req, res, "apiAuthPage", "API module has no OAuth handlers."
        else
            m.oauth.process req, res

    # The manager overview page.
    managerPage = (req, res) ->
        id = req.params.id
        m = manager.modules[id]

        # Check if manager is enabled and running.
        if not m?
            sendErrorResponse req, res, "managerPage", "Manager not found or not active."
            return

        fs.readFile "#{__dirname}/manager/#{m.moduleNameLower.replace("manager", "")}.coffee", {encoding: settings.general.encoding}, (err, data) ->
            lines = data.split "\n"
            lines.splice 0, 2
            description = ""

            # Iterate first lines of the module code to get its description.
            for i in lines
                if i.substring(0, 1) is "#"
                    description += i.replace("#", "") + "\n"
                else
                    options = {title: m.moduleName, description: description, errors: m.errors, data: m.data}

                    return renderPage req, res, "manager", options

    # Returns data from the manager.
    managerDataPage = (req, res) ->
        id = req.params.id
        m = manager.modules[id]

        # Check if API module is enabled and running.
        if not m?
            sendErrorResponse req, res, "managerDataPage", "Manager not found or not active."
            return

        # Create options object.
        options = {}
        options.settings = settings[m.moduleName]
        options.moduleName = m.moduleName
        options.data = m.data
        options.errors = m.errors

        expresser.app.renderJson req, res, options

    # RENDER METHODS
    # -------------------------------------------------------------------------

    # Helper to render pages.
    renderPage = (req, res, filename, options) ->
        return if not checkSecurity req, res

        logger.info "Routes.renderPage", req.path, filename

        options = {} if not options?
        options.pageTitle = filename if not options.pageTitle?
        options.title = settings.app.title if not options.title?
        options.loadJs = [] if not options.loadJs?
        options.loadCss = [] if not options.loadCss?
        options.moment = moment
        options.server = utils.system.getInfo()
        options.managerModules = manager.modules

        # Force .jade extension.
        filename += ".jade" if filename.indexOf(".jade") < 0

        # Render page.
        expresser.app.renderView req, res, filename, options

    # SECURITY METHODS
    # -------------------------------------------------------------------------

    # Check if request is allowed by getting the client's IP.
    # IP is calculated based on the subnet setting.
    checkSecurity = (req, res) ->
        return true if not settings.app.checkSecurity

        ipClient = req.headers["X-Forwarded-For"] or req.connection.remoteAddress or req.socket?.remoteAddress

        return true if utils.network.ipInRange ipClient, settings.network.subnet

        # Oops, access denied.
        sendAccessDenied req, res, ipClient
        return false

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Send access denied / not authorized response.
    sendAccessDenied = (req, res, ipClient) ->
        logger.warn "Routes.sendAccessDenied", req.url, ipClient

        res.status 401
        res.json {error: "Access denied for #{ipClient}."}

    # When the server can't return a valid result,
    # send an error response with status code 500.
    sendErrorResponse = (req, res, method, message) ->
        logger.error "HTTP Error", method, message

        message = JSON.stringify message
        res.status 500
        res.json {error: message, method: method}

# Singleton implementation.
# -----------------------------------------------------------------------------
Routes.getInstance = ->
    @instance = new Routes() if not @instance?
    return @instance

module.exports = exports = Routes.getInstance()
