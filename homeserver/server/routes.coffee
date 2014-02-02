# SERVER: ROUTES
# -----------------------------------------------------------------------------
# All server routes are defined here.
class Routes

    expresser = require "expresser"
    cron = expresser.cron
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    commander = require "./commander.coffee"
    emailApi = require "./api/email.coffee"
    fs = require "fs"
    fitbit = require "./api/fitbit.coffee"
    homeManager = require "./manager/home.coffee"
    hueApi = require "./api/hue.coffee"
    netatmoApi = require "./api/netatmo.coffee"
    networkApi = require "./api/network.coffee"
    ninjaApi = require "./api/ninja.coffee"
    path = require "path"
    security = require "./security.coffee"
    toshlApi = require "./api/toshl.coffee"
    withingsApi = require "./api/withings.coffee"
    wundergroundApi = require "./api/wunderground.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Set most routes on init. The app (from Expresser) must be passed here.
    init: (callback) =>
        app = expresser.app.server

        # Main route.
        app.get "/", indexPage

        # API routes.
        app.get "/api/home", apiHome
        app.get "/api/commander/:cmd", apiCommander
        app.post "/api/commander/:cmd", apiCommander

        # Email routes.
        app.get "/email", emailPage

        # Fitbit routes.
        app.get "/fitbit", fitbitPage
        app.get "/fitbit/auth", fitbitAuth
        app.get "/fitbit/auth/callback", fitbitAuthCallback
        app.post "/fitbit/auth/callback", fitbitAuthCallback

        # Home rules.
        app.get "/home", homePage
        app.get "/home/lights", homeLightsPage

        # Netatmo routes.
        app.get "/netatmo", netatmoPage
        app.get "/netatmo/auth", netatmoAuth
        app.get "/netatmo/auth/callback", netatmoAuthCallback
        app.post "/netatmo/auth/callback", netatmoAuthCallback

        # Ninja Blocks routes.
        app.get "/ninja", ninjaPage

        # Status route.
        app.get "/status", statusPage

        # System routes.
        app.get "/system/jobs", systemJobsPage
        app.get "/system/network", systemNetworkPage

        # Toshl routes.
        app.get "/toshl", toshlPage
        app.get "/toshl/auth", toshlAuth
        app.get "/toshl/auth/callback", toshlAuthCallback
        app.post "/toshl/auth/callback", toshlAuthCallback

        # Withings routes.
        app.get "/withings", withingsPage
        app.get "/withings/auth", withingsAuth
        app.get "/withings/auth/callback", withingsAuthCallback
        app.post "/withings/auth/callback", withingsAuthCallback

        # Weather underground routes.
        app.get "/wunderground", wundergroundPage

        callback() if callback?

    # MAIN ROUTES
    # -------------------------------------------------------------------------

    # The index homepage.
    indexPage = (req, res) ->
        renderPage req, res, "index"

    # API ROUTES
    # -------------------------------------------------------------------------

    # The home data endpoint.
    apiHome = (req, res) ->
        renderData req, res, homeManager.data
        
    # The commander processor.
    apiCommander = (req, res) ->
        commander.execute req.params.cmd, req.body, (err, result) ->
            if err?
                res.json {error: err}
            else
                res.json result

    # EMAIL ROUTES
    # -------------------------------------------------------------------------

    # Main Email entrance page.
    emailPage = (req, res) ->
        emailApi.getDashboard (err, result) -> renderPage req, res, "email", {err: err, result: result}

    # FITBIT ROUTES
    # -------------------------------------------------------------------------

    # Main Fitbit entrance page.
    fitbitPage = (req, res) ->
        fitbitApi.getDashboard (err, result) -> renderPage req, res, "fitbit", {err: err, result: result}

    # Get Fitbit OAuth tokens.
    fitbitAuth = (req, res) ->
        fitbitApi.auth req, res

    # Callback for Fitbit OAuth.
    fitbitAuthCallback = (req, res) ->
        fitbitApi.auth req, res

    # HOME ROUTES
    # -------------------------------------------------------------------------

    # Main home page.
    homePage = (req, res) ->
        options = {pageTitle: "Home", data: [hueApi, netatmoApi, withingsApi]}
        renderPage req, res, "home", options

    # Home light control page.
    homeLightsPage = (req, res) ->
        options = {pageTitle: "Home lights", data: [hueApi, ninjaApi]}
        renderPage req, res, "home.lights", options

    # NETATMO ROUTES
    # -------------------------------------------------------------------------

    # Main Netatmo entrance page.
    netatmoPage = (req, res) ->
        netatmoApi.getDashboard (err, result) -> renderPage req, res, "netatmo", {err: err, result: result}

    # Get Netatmo OAuth tokens.
    netatmoAuth = (req, res) ->
        netatmoApi.auth req, res

    # Callback for Netatmo OAuth.
    netatmoAuthCallback = (req, res) ->
        netatmoApi.auth req, res

    # NINJA BLOCKS ROUTES
    # -------------------------------------------------------------------------

    # Main Fitbit entrance page.
    ninjaPage = (req, res) ->
        ninjaApi.getDashboard (err, result) -> renderPage req, res, "ninja", {err: err, result: result}

    # PHONE CLIENT ROUTES
    # -------------------------------------------------------------------------

    # Phone client: retrieve fitness data.
    phoneFitness = (req, res) ->
        console.warn 1

    # Phone client: retrieve home data.
    phoneHome = (req, res) ->
        console.warn 1

    # Phone client: retrieve weather data.
    phoneWeather = (req, res) ->
        console.warn 1

    # STATUS ROUTES
    # -------------------------------------------------------------------------

    # Main status page.
    statusPage = (req, res) ->
        res.json utils.getServerInfo()

    # SYSTEM ROUTES
    # -------------------------------------------------------------------------

    # Cron jobs page.
    systemJobsPage = (req, res) ->
        renderPage req, res, "system.jobs", {pageTitle: "Scheduled jobs", jobs: cron.jobs}

    # Network overview page.
    systemNetworkPage = (req, res) ->
        renderPage req, res, "system.network", {pageTitle: "Network overview", status: network.status}

    # TOSHL ROUTES
    # -------------------------------------------------------------------------

    # Main Toshl entrance page.
    toshlPage = (req, res) ->
        toshlApi.getDashboard (err, result) -> renderPage req, res, "toshl", {err: err, result: result}

    # Get Toshl OAuth tokens.
    toshlAuth = (req, res) ->
        toshlApi.auth req, res

    # Callback for Toshl OAuth.
    toshlAuthCallback = (req, res) ->
        toshlApi.auth req, res

    # WITHINGS ROUTES
    # -------------------------------------------------------------------------

    # Main Withings entrance page.
    withingsPage = (req, res) ->
        withingsApi.getDashboard (err, result) -> renderPage req, res, "withings", {err: err, result: result}

    # Get Withings OAuth tokens.
    withingsAuth = (req, res) ->
        withingsApi.auth req, res

    # Callback for Withings OAuth.
    withingsAuthCallback = (req, res) ->
        withingsApi.auth req, res

    # WUNDERGROUND ROUTES
    # -------------------------------------------------------------------------

    # Main Weather Underground entrance page.
    wundergroundPage = (req, res) ->
        wundergroundApi.getCurrentWeather (err, result) -> renderPage req, res, "wunderground", {err: err, result: result}

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Helper to render JSON data (mainly used by the /api/ routes).
    renderData = (req, res, data) ->
        res.json data

    # Helper to render pages.
    renderPage = (req, res, filename, options) ->
        options = {} if not options?
        options.pageTitle = filename if not options.pageTitle?
        options.title = settings.general.appTitle if not options.title?
        options.loadJs = [] if not options.loadJs?

        # Data to be included.
        if options.data?
            options[d.moduleId] = d.data for d in options.data
            delete options.data

        # Check if current view have an external JS to be loaded.
        jsName = filename.replace "jade",""
        jsPath = path.resolve __dirname, "../", "assets/js/views/#{jsName}.coffee"
        options.loadJs.push "views/#{jsName}.js" if fs.existsSync jsPath

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