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
                app.get "/#{link}", (req, res) ->
                    options = {pageTitle: m.title, data: m.data}
                    renderPage req, res, link, options


        # API modules routes.
        for key, m of api.modules
            do (m) ->
                app.get "/#{m.moduleId}", (req, res) ->
                    renderApiModulePage req, res, m

                # Has OAuth bindings?
                if m.oauth?
                    oauthProcess = (req, res) -> m.oauth.process req, res
                    app.get "/#{m.moduleId}/auth", oauthProcess
                    app.get "/#{m.moduleId}/auth/callback", oauthProcess
                    app.post "/#{m.moduleId}/auth/callback", oauthProcess

        # API list, commander and status routes.
        app.get "/api", apiPage
        app.get "/commander/:cmd", commanderPage
        app.post "/commander/:cmd", commanderPage
        app.get "/status", statusPage

        callback() if callback?

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
                res.json {error: err}
            else
                res.json result

    # Main status page.
    statusPage = (req, res) ->
        res.json utils.getServerInfo()

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Helper to show an overview about the specified API module.
    renderApiModulePage = (req, res, module) ->
        options = {title: module.moduleName, data: module.data}
        renderPage req, res, "apiModule", options

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

    # When the server can't return a valid result,
    # send an error response with status code 500.
    sendErrorResponse = (res, method, message) ->
        message = JSON.stringify message
        res.statusCode = 500
        res.send "Error: #{method} - #{message}"
        expresser.logger.error "HTTP Error", method, message

    # Log the request to the console if `debug` is true.
    logRequest = (method, params) ->
        if expresser.settings.general.debug
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