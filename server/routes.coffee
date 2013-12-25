# SERVER: ROUTES
# -----------------------------------------------------------------------------
# All server routes are defined here.
class Routes

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    fitbit = require "./api/fitbit.coffee"
    security = require "./security.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Set most routes on init. The app (from Expresser) must be passed here.
    init: =>
        app = expresser.app.server

        # Main routes.
        app.get "/", indexPage

        # Fitbit routes.
        app.get "/fitbit", fitbitPage
        app.get "/fitbit/auth", fitbitAuth
        app.get "/fitbit/auth/callback", fitbitAuthCallback
        app.post "/fitbit/auth/callback", fitbitAuthCallback


    # MAIN ROUTES
    # -------------------------------------------------------------------------

    # The index homepage.
    indexPage = (req, res) ->
        renderPage req, res, "index"

    # FITBIT ROUTES
    # -------------------------------------------------------------------------

    # Main Fitbit entrance page.
    fitbitPage = (req, res) ->
        fitbit.getSleepData "2013-12-01"

    # Get Fitbit OAuth tokens.
    fitbitAuth = (req, res) ->
        fitbit.auth req, res

    # Callback for Fitbit OAuth.
    fitbitAuthCallback = (req, res) ->
        fitbit.auth req, res


    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Helper to render pages.
    renderPage = (req, res, file, options) ->
        options = {} if not options?
        options.title = settings.general.appTitle if not options.title?

        res.render file, options

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