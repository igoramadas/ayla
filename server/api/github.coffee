# GITHUB API
# -----------------------------------------------------------------------------
# NOT READY YET! Get and post programming related data to GitHub.
# More info at https://developer.github.com/v3.
class GitHub extends (require "./baseapi.coffee")

    expresser = require "expresser"

    logger = expresser.logger
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the GitHub module.
    init: =>
        @baseInit()

    # Start collecting data from GitHub.
    start: =>
        @baseStart()

    # Stop collecting data from GitHub.
    stop: =>
        @baseStop()


# Singleton implementation.
# -----------------------------------------------------------------------------
GitHub.getInstance = ->
    @instance = new GitHub() if not @instance?
    return @instance

module.exports = exports = GitHub.getInstance()
