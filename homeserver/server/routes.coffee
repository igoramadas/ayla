# SERVER: ROUTES
# -----------------------------------------------------------------------------
# All server routes are defined here.
class Routes

    expresser = require "expresser"
    cron = expresser.cron
    database = expresser.database
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings
    utils = expresser.utils

    api = require "./api.coffee"
    commander = require "./commander.coffee"
    fs = require "fs"
    lodash = expresser.libs.lodash
    manager = require "./manager.coffee"
    path = require "path"

    # Holds a list of all valid access tokens.
    tokenCache = {}

    # INIT
    # -------------------------------------------------------------------------

    # Set most routes on init. The app (from Expresser) must be passed here.
    init: (callback) =>
        app = expresser.app.server

        # Main route.
        app.get "/", indexPage

        # Start routes.
        app.get "/start", startPage
        app.get "/start/data", startDataPage

        # Used by clients to get or renew an access token. This is mainly used
        # via NFC tags, for example an NFC tag on the entrance door that
        # publishes this URL to the mobile app / browser.
        app.get "/tokenrequest", tokenRequestPage

        # Commander and status routes.
        app.get "/commander/:cmd", commanderPage
        app.post "/commander/:cmd", commanderPage

        # Bind API module routes.
        app.get "/api/:id", apiPage
        app.get "/api/:id/data", apiDataPage
        app.get "/api/:id/auth", apiAuthPage
        bindModuleRoutes m for key, m of api.modules

        # Bind manager routes.
        app.get "/manager/:id", managerPage
        app.get "/manager/:id/data", managerDataPage
        bindModuleRoutes m for key, m of manager.modules

        # Init the access tokens collection.
        for token, value of settings.accessTokens
            tokenCache[token] = value
            tokenCache[token].permanent = true

        callback() if callback?

    # Helper to bind module routes.
    bindModuleRoutes = (m) ->
        return if m.routes.length < 1

        app = expresser.app.server

        for route in m.routes
            method = route.method.toLowerCase()

            # Get or post? Available render types are page, json and image.
            app[method] "/#{m.moduleName}/#{route.path}", (req, res) ->
                if route.render is "json"
                    renderFn = renderJson
                else if route.render is "image"
                    renderFn = renderImage
                else
                    renderFn = renderPage

                renderFn req, res, route.callback(req), route.options

    # MAIN ROUTES
    # -------------------------------------------------------------------------

    # Main route will mostly redirect to start page.
    indexPage = (req, res) ->
        res.redirect "/start"

    # The index homepage.
    startPage = (req, res) ->
        renderPage req, res, "start", {pageTitle: "Start"}

    # Data returned on the start page.
    startDataPage = (req, res) ->
        result = []
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

        # Get details for managers..
        for key, m of manager.modules
            obj = {id: key, moduleName: m.moduleName, errors: m.errors, data: []}
            managerModules.push obj
            populateData m.data, obj.data

        # Get details for API modules.
        for key, m of api.modules
            obj = {id: key, moduleName: m.moduleName, errors: m.errors, data: [], jobs: []}
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
        result.push {key: "server", data: utils.getServerInfo()}
        result.push {key: "managerModules", data: managerModules}
        result.push {key: "disabledManagerModules", data: lodash.keys manager.disabledModules}
        result.push {key: "apiModules", data: apiModules}
        result.push {key: "disabledApiModules", data: lodash.keys api.disabledModules}
        result.push {key: "jobs", data: jobs}

        renderJson req, res, result

    # The token request page.
    tokenRequestPage = (req, res) ->
        ipClient = req.headers['X-Forwarded-For'] or req.connection.remoteAddress or req.socket?.remoteAddress
        ipRouter = settings.network.router.ip

        # Check if client is connected to home network.
        clientSubnet = ipClient.substring(0, ipClient.lastIndexOf ".")
        routerSubnet = ipRouter.substring(0, ipRouter.lastIndexOf ".")

        if clientSubnet isnt routerSubnet and not settings.general.debug
            return sendAccessDenied req, res, ipClient

        # Create a temporary token and send to client.
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        token = ""
        i = 0
        while i < 5
            token += chars.charAt Math.floor(Math.random() * chars.length)
            i++

        # Add temp token to cache and send back to client.
        tokenCache[token] = {device: req.params.device, expires: moment().add 5, "d"}
        renderJson req, res, {result: tokenCache[token]}

    # The commander processor.
    commanderPage = (req, res) ->
        commander.execute req.params.cmd, req.body, (err, result) ->
            if err?
                sendErrorResponse req, res, "commanderPage", err
            else
                renderJson req, res, result

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
                    options = {title: m.moduleName, description: description, jobs: jobs, errors: m.errors, data: m.data}
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
        options.oauth = m.oauth
        options.jobs = []

        jobs = lodash.where cron.jobs, {module: m.moduleName + ".coffee"}

        for job in jobs
            options.jobs.push {id: job.id, schedule: job.schedule, endTime: job.endTime}

        renderJson req, res, options

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

                    return renderPage req, res, "api", options

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

        renderJson req, res, options

    # RENDER METHODS
    # -------------------------------------------------------------------------

    # Helper to render pages.
    renderPage = (req, res, filename, options) ->
        return if not checkSecurity req, res

        logger.info "Routes.renderPage", req.path, filename

        options = {} if not options?
        options.pageTitle = filename if not options.pageTitle?
        options.title = settings.general.appTitle if not options.title?
        options.loadJs = [] if not options.loadJs?
        options.loadCss = [] if not options.loadCss?
        options.moment = moment
        options.server = utils.getServerInfo()
        options.managerModules = manager.modules

        # Force .jade extension.
        filename += ".jade" if filename.indexOf(".jade") < 0

        # Render page.
        res.render filename, options

    # Render response as JSON data.
    renderJson = (req, res, data) ->
        return if not checkSecurity req, res

        logger.info "Routes.renderJson", req.path

        # Remove methods from JSON before rendering.
        cleanJson = (obj) ->
            if lodash.isArray obj
                cleanJson i for i in obj
            else if lodash.isObject obj
                for k, v of obj
                    if lodash.isFunction v
                        delete obj[k]
                    else
                        cleanJson v

        cleanJson data

        # Add Access-Control-Allow-Origin to all when debug is true.
        if settings.general.debug
            res.setHeader "Access-Control-Allow-Origin", "*"

        # Send JSON response.
        res.json data

    # Render response as image.
    renderImage = (req, res, filename, options) ->
        return if not checkSecurity req, res

        mimetype = options?.mimetype

        if not mimetype?
            extname = path.extname(filename).toLowerCase().replace(".","")
            extname = "jpeg" if extname is "jpg"
            mimetype = "image/#{extname}"

        res.contentType mimetype
        res.sendFile filename

    # SECURITY METHODS
    # -------------------------------------------------------------------------

    # Check if request is allowed by getting the client's IP and if coming
    # from a remote address, check if it's using a valid user token.
    # IP is calculated based on the `settings.network.router.ip` value.
    checkSecurity = (req, res) ->
        return true
        ipClient = req.headers["X-Forwarded-For"] or req.connection.remoteAddress or req.socket?.remoteAddress

        # Valid token? Grant access.
        # Also check if a token cookie should be set for this particular client.
        token = req.query.token
        if token? and settings.accessTokens[token]?
            expires = {expires: moment().add(settings.app.cookieTokenExpireDays, "d").toDate()}
            res.cookie "token", token, expires
            return true

        # Check if token is present as a cookie.
        cookie = req.cookies?.token
        if cookie? and settings.accessTokens[cookie]?
            return true

        # Oops, access denied.
        sendAccessDenied req, res, ipClient
        return false

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Send access denied / not authorized response.
    sendAccessDenied = (req, res, ipClient) ->
        logger.warn "Routes.sendAccessDenied", req.url, ipClient

        res.status 401
        res.json {error: "Access denied or invalid token for #{ipClient}."}

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
