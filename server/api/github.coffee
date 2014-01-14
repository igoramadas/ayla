# GITHUB API
# -----------------------------------------------------------------------------
class GitHub extends (require "./baseApi.coffee")

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------
    
    # Init the GitHub module.
    init: =>
        @baseInit()
    
    # Start collecting weather data.
    start: =>
        @baseStart()
    
    # Stop collecting weather data.
    stop: =>
        @baseStop()


# Singleton implementation.
# -----------------------------------------------------------------------------
GitHub.getInstance = ->
    @instance = new GitHub() if not @instance?
    return @instance

module.exports = exports = GitHub.getInstance()