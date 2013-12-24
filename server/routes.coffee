# SERVER: ROUTES
# -----------------------------------------------------------------------------
# All server routes are defined here.
class Routes

    expresser = require "expresser"
    logger = expresser.logger

    security = require "./security.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Set most routes on init. The app (from Expresser) must be passed here.
    init: (app) =>

        # Passport auth helper.
        passportAuth = security.passport.authenticate
        passportOptions = {failureRedirect: "/?error=auth_failed" }

        # Main routes.
        app.get "/", indexPage

        # Fitbit routes.
        app.get "/fitbit", fitbitPage
        app.get "/fitbit/auth", passportAuth("fitbit")
        app.get "/fitbit/auth/callback", passportAuth("fitbit", passportOptions), fitbitAuthCallback

    # MAIN ROUTES
    # -------------------------------------------------------------------------

    # The index homepage.
    indexPage = (req, res) ->
        logRequest "indexPage"

        renderPage req, res, "index",
            title: expresser.settings.general.appTitle

    # FITBIT ROUTES
    # -------------------------------------------------------------------------

    # Main Fitbit entrance page.
    fitbitPage = (req, res) ->
        logRequest "fitbitPage"

        res.redirect "/fitbit"

    # Callback for Fitbit OAuth.
    fitbitAuthCallback = (req, res) ->
        logRequest "fitbitAuthCallback"

        res.redirect "/fitbit"

    # HELPER METHODS
    # -------------------------------------------------------------------------

    # Helper to render pages.
    renderPage = (req, res, file, options) ->
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