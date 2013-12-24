# SERVER: API
# -----------------------------------------------------------------------------
# Wrapper for all server API modules.
class Api

    expresser = require "expresser"
    logger = expresser.logger

    # Init Jarbas API.
    camera = require "./server/api/camera.coffee"
    email = require "./server/api/email.coffee"
    endomondo = require "./server/api/endomondo.coffee"
    fitbit = require "./server/api/fitbit.coffee"
    github = require "./server/api/github.coffee"
    hue = require "./server/api/hue.coffee"
    ninja = require "./server/api/ninja.coffee"
    toshl = require "./server/api/toshl.coffee"
    withings = require "./server/api/withings.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init Jarbas API.
    init: ->
        camera.init()
        email.init()


# Singleton implementation.
# -----------------------------------------------------------------------------
Api.getInstance = ->
    @instance = new Api() if not @instance?
    return @instance

module.exports = exports = Api.getInstance()