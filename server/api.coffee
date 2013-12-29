# SERVER: API
# -----------------------------------------------------------------------------
# Wrapper for all server API modules.
class Api

    expresser = require "expresser"
    logger = expresser.logger

    # Init Jarbas API.
    camera = require "./api/camera.coffee"
    email = require "./api/email.coffee"
    endomondo = require "./api/endomondo.coffee"
    fitbit = require "./api/fitbit.coffee"
    github = require "./api/github.coffee"
    hue = require "./api/hue.coffee"
    ninja = require "./api/ninja.coffee"
    toshl = require "./api/toshl.coffee"
    withings = require "./api/withings.coffee"
    wunderground = require "./api/wunderground.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init Jarbas API.
    init: ->
        camera.init()
        email.init()
        fitbit.init()
        hue.init()
        ninja.init()
        withings.init()
        wunderground.init()


# Singleton implementation.
# -----------------------------------------------------------------------------
Api.getInstance = ->
    @instance = new Api() if not @instance?
    return @instance

module.exports = exports = Api.getInstance()