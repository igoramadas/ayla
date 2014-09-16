# GITHUB API
# NOT READY YET!!!
# -----------------------------------------------------------------------------
# Module for GitHub integration.
class GitHub extends (require "./baseapi.coffee")

    expresser = require "expresser"

    logger = expresser.logger
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the GitHub module.
    init: =>
        @baseInit()

    # Start collecting data from Github.
    start: =>
        @baseStart()

    # Stop collecting data from Github.
    stop: =>
        @baseStop()


# Singleton implementation.
# -----------------------------------------------------------------------------
GitHub.getInstance = ->
    @instance = new GitHub() if not @instance?
    return @instance

module.exports = exports = GitHub.getInstance()
