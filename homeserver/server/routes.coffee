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
    fs = require "fs"
    fitbitApi = require "./api/fitbit.coffee"
    fitnessManager = require "./manager/fitness.coffee"
    hueApi = require "./api/hue.coffee"
    lodash = expresser.libs.lodash
    netatmoApi = require "./api/netatmo.coffee"
    networkApi = require "./api/network.coffee"
    ninjaApi = require "./api/ninja.coffee"
    path = require "path"
    security = require "./security.coffee"
    toshlApi = require "./api/toshl.coffee"
    weatherManager = require "./manager/weather.coffee"
    withingsApi = require "./api/withings.coffee"
    wundergroundApi = require "./api/wunderground.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Set most routes on init. The app (from Expresser) must be passed here.
    init: (callback) =>
        app = expresser.app.server

        # Main routes.
        app.get "/", indexPage
        app.get "/fitness", fitnessPage
        app.get "/lights", lightsPage
        app.get "/system", systemPage
        app.get "/weather", weatherPage

        # API related routes.
        app.get "/api/home", apiHome
        app.get "/api/commander/:cmd", apiCommander
        app.post "/api/commander/:cmd", apiCommander
        app.get "/fitbit", fitbitPage
        app.get "/fitbit/auth", fitbitAuth
        app.get "/fitbit/auth/callback", fitbitAuthCallback
        app.post "/fitbit/auth/callback", fitbitAuthCallback
        app.get "/netatmo", netatmoPage
        app.get "/netatmo/auth", netatmoAuth
        app.get "/netatmo/auth/callback", netatmoAuthCallback
        app.post "/netatmo/auth/callback", netatmoAuthCallback
        app.get "/network", networkPage
        app.get "/ninja", ninjaPage
        app.get "/status", statusPage
        app.get "/toshl", toshlPage
        app.get "/toshl/auth", toshlAuth
        app.get "/toshl/auth/callback", toshlAuthCallback
        app.post "/toshl/auth/callback", toshlAuthCallback
        app.get "/withings", withingsPage
        app.get "/withings/auth", withingsAuth
        app.get "/withings/auth/callback", withingsAuthCallback
        app.post "/withings/auth/callback", withingsAuthCallback
        app.get "/wunderground", wundergroundPage

        callback() if callback?

    # MAIN ROUTES
    # -------------------------------------------------------------------------

    # The index homepage.
    indexPage = (req, res) ->
        renderPage req, res, "index"

    # Fitness info page.
    fitnessPage = (req, res) ->
        options = {pageTitle: "Fitness", data: fitnessManager.data}
        renderPage req, res, "fitness", options

    # L:ight control page.
    lightsPage = (req, res) ->
        options = {pageTitle: "Home lights", data: {hue: hueApi.data, ninja: ninjaApi.data}}
        renderPage req, res, "home.lights", options

    # System info page.
    systemPage = (req, res) ->
        renderPage req, res, "system.jobs", {pageTitle: "Scheduled jobs", jobs: cron.jobs}

    # Weather info page.
    weatherPage = (req, res) ->
        options = {pageTitle: "Weather", data: weatherManager.data}
        renderPage req, res, "weather", options

    # API ROUTES
    # -------------------------------------------------------------------------

    # The home data endpoint.
    apiHome = (req, res) ->
        renderData req, res, weatherManager.data
        
    # The commander processor.
    apiCommander = (req, res) ->
        commander.execute req.params.cmd, req.body, (err, result) ->
            if err?
                res.json {error: err}
            else
                res.json result

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

    # NETWORK ROUTES
    # -------------------------------------------------------------------------

    # Network overview page.
    networkPage = (req, res) ->
        renderPage req, res, "network", {pageTitle: "Network overview", data: networkApi.data}

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
        renderPage req, res, "wunderground", {err: err, result: result}

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
        options.loadCss = [] if not options.loadCss?

        # Set base file name.
        baseName = filename.replace ".jade",""

        # Check if current view has an external JS to be loaded.
        jsPath = path.resolve __dirname, "../", "assets/js/views/#{baseName}.coffee"
        options.loadJs.push "views/#{baseName}.js" if fs.existsSync jsPath

        # Check if current view has an external CSS to be loaded.
        cssPath = path.resolve __dirname, "../", "assets/css/#{baseName}.styl"
        options.loadCss.push "#{baseName}.css" if fs.existsSync cssPath

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