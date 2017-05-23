# DROPBOX API
# -----------------------------------------------------------------------------
# NOT READY YET! Module to connect and manage files on Dropbox.
# More info at https://www.dropbox.com/developers.
class Dropbox extends (require "./baseapi.coffee")

    expresser = require "expresser"

    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings

    querystring = require "querystring"

    # INIT
    # -------------------------------------------------------------------------

    # Init the Dropbox module.
    init: =>
        @baseInit()

    # Start the Dropbox module.
    start: =>
        @baseStart()

        @oauthInit (err, result) =>
            if err?
                @logError "Dropbox.start", err

    # Stop the Dropbox module.
    stop: =>
        @baseStop()

    # API BASE METHODS
    # -------------------------------------------------------------------------

    # Make a request to the Dropbox API.
    apiRequest: (urlpath, params, callback) =>
        if lodash.isFunction params
            callback = params
            params = null

        if not @isRunning [@oauth.authenticated]
            callback "Module not running or OAuth client not ready. Please check Dropbox API settings."
            return

        # Make request using OAuth.
        @oauth.get reqUrl, (err, result) =>
            result = JSON.parse result if lodash.isString result
            callback err, result

# Singleton implementation.
# -----------------------------------------------------------------------------
Dropbox.getInstance = ->
    @instance = new Dropbox() if not @instance?
    return @instance

module.exports = exports = Dropbox.getInstance()
