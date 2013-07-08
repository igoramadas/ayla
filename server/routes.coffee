# ROUTES
# -----------------------------------------------------------------------------

# Required modules.
expresser = require "expresser"

# Environment variables.
env = process.env

# Set routes.
exports.set = (app) ->
    app.get "/", exports.indexPage
    app.get "/camera/:id", exports.cameraProxy


# ROUTE METHODS
# -----------------------------------------------------------------------------

# The index homepage.
exports.indexPage = (req, res) ->
    logRequest "indexPage"

    renderPage req, res, "index",
        title: expresser.settings.general.appTitle

# Proxy to serve camera images.
exports.cameraProxy = (req, res) ->
    logRequest "cameraProxy"

    # Get camera variable.
    camera = env["CAMERA_#{req.params.id}"]


# HELPER METHODS
# -----------------------------------------------------------------------------

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