# SERVER: ROUTES
# -----------------------------------------------------------------------------
# All server routes are defined here.
class Routes

    expresser = require "expresser"
    cron = expresser.cron
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    api = require "./api.coffee"
    commander = require "./commander.coffee"
    fs = require "fs"
    lodash = expresser.libs.lodash
    manager = require "./manager.coffee"
    path = require "path"

    # INIT
    # -------------------------------------------------------------------------

    # Set most routes on init. The app (from Expresser) must be passed here.
    init: (callback) =>
        app = expresser.app.server

        # Main route.
        app.get "/", indexPage

        # Manager routes.
        for key, m of manager.modules
            do (m) ->
                link = m.title.toLowerCase()

                # Set default manager routes (/managerId and /managerId/data).
                app.get "/#{link}", (req, res) -> renderPage req, res, link, {pageTitle: m.title, data: m.data}
                app.get "/#{link}/data", (req, res) -> renderJson req, res, m.data

                # Bind manager specific routes.
                bindModuleRoutes m

        # API modules routes.
        for key, m of api.modules
            do (m) ->
                link = m.moduleId

                # Set default module route (/apiModuleId).
                app.get "/#{link}", (req, res) -> renderApiModulePage req, res, m

                # Has OAuth bindings? If so, set OAuth routes.
                if m.oauth?
                    oauthProcess = (req, res) -> m.oauth.process req, res
                    app.get "/#{m.moduleId}/auth", oauthProcess
                    app.get "/#{m.moduleId}/auth/callback", oauthProcess
                    app.post "/#{m.moduleId}/auth/callback", oauthProcess

                # Bind API module specific routes.
                bindModuleRoutes m

        # API page, commander and status routes.
        app.get "/api", apiPage
        app.get "/commander/:cmd", commanderPage
        app.post "/commander/:cmd", commanderPage
        app.get "/status", statusPage

        callback() if callback?

    # Helper to bind module routes.
    bindModuleRoutes = (m) ->
        return if m.routes.length < 1

        app = expresser.app.server

        for route in m.routes
            method = route.method.toLowerCase()

            # Get or post? Available render types are page, json and image.
            app[method] "/#{m.moduleId}/#{route.path}", (req, res) ->
                if route.render is "page"
                    renderFn = renderPage
                else if route.render is "json"
                    renderFn = renderJson
                else if route.render is "image"
                    renderFn = renderImage

                renderFn req, res, route.callback(req), route.options

    # MAIN ROUTES
    # -------------------------------------------------------------------------

    # The index homepage.
    indexPage = (req, res) ->
        renderPage req, res, "index"

    # API, COMMANDER AND STATUS ROUTES
    # -------------------------------------------------------------------------

    # The API modules listing.
    apiPage = (req, res) ->
        renderPage req, res, "api", {title: "API Modules", apiModules: api.modules}

    # The commander processor.
    commanderPage = (req, res) ->
        commander.execute req.params.cmd, req.body, (err, result) ->
            if err?
                renderJson req, res, {error: err}
            else
                renderJson req, res, result

    # Main status page.
    statusPage = (req, res) ->
        renderJson req, res, utils.getServerInfo()

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Helper to show an overview about the specified API module.
    renderApiModulePage = (req, res, module) ->
        options = {title: module.moduleName, data: module.data}
        renderPage req, res, "apimodule", options

    # Helper to render pages.
    renderPage = (req, res, filename, options) ->
        options = {} if not options?
        options.pageTitle = filename if not options.pageTitle?
        options.title = settings.general.appTitle if not options.title?
        options.loadJs = [] if not options.loadJs?
        options.loadCss = [] if not options.loadCss?

        # Set base file name.
        baseName = filename.replace ".jade",""

        # Check if current view has an external JS to be loaded.
        jsPath = path.resolve __dirname, "../", "assets/js/views/#{baseName}.coffee"
        options.loadJs.push "views/#{baseName}.js" if fs.existsSync jsPath

        # Check if current view has an external CSS to be loaded.
        cssPath = path.resolve __dirname, "../", "assets/css/#{baseName}.styl"
        options.loadCss.push "#{baseName}.css" if fs.existsSync cssPath

        # Append managers to the output.
        options.managers = manager.modules

        # Force .jade extension.
        filename += ".jade" if filename.indexOf(".jade") < 0

        # Render page.
        res.render filename, options

    # Render response as JSON data.
    renderJson = (req, res, data) ->
        res.json data

    # Render response as image.
    renderImage = (req, res, filename, options) ->
        mimetype = options?.mimetype

        if not mimetype?
            extname = path.extname(filename).toLowerCase().replace(".","")
            extname = "jpeg" if extname is "jpg"
            mimetype = "image/#{extname}"

        res.contentType mimetype
        res.sendfile filename

    # When the server can't return a valid result,
    # send an error response with status code 500.
    sendErrorResponse = (res, method, message) ->
        message = JSON.stringify message
        res.statusCode = 500
        res.send "Error: #{method} - #{message}"
        logger.error "HTTP Error", method, message

    # Log the request to the console if `debug` is true.
    logRequest = (method, params) ->
        if settings.general.debug
            if params?
                console.log "Request", method, params
            else
                console.log "Request", method


# Singleton implementation.
# -----------------------------------------------------------------------------
Routes.getInstance = ->
    @instance = new Routes() if not @instance?
    return @instance

module.exports = exports = Routes.getInstance()
