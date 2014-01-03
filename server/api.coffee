# SERVER: API
# -----------------------------------------------------------------------------
# Wrapper for all server API modules.
class Api

    expresser = require "expresser"
    cron = expresser.cron
    logger = expresser.logger
    settings = expresser.settings

    camera = require "./api/camera.coffee"
    email = require "./api/email.coffee"
    endomondo = require "./api/endomondo.coffee"
    fitbit = require "./api/fitbit.coffee"
    github = require "./api/github.coffee"
    hue = require "./api/hue.coffee"
    netatmo = require "./api/netatmo.coffee"
    network = require "./network.coffee"
    ninja = require "./api/ninja.coffee"
    path = require "path"
    toshl = require "./api/toshl.coffee"
    withings = require "./api/withings.coffee"
    wunderground = require "./api/wunderground.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init Ayla API.
    init: ->
        rootPath = path.join __dirname, "../"
        cronPath = rootPath + settings.path.data + "cron.json"
        apiPath = rootPath + "server/api/"

        # Load cron jobs.
        cron.load cronPath, {basePath: apiPath}

        # Init modules.
        camera.init()
        email.init()
        fitbit.init()
        hue.init()
        network.init()
        ninja.init()
        toshl.init()
        withings.init()
        wunderground.init()


# Singleton implementation.
# -----------------------------------------------------------------------------
Api.getInstance = ->
    @instance = new Api() if not @instance?
    return @instance

module.exports = exports = Api.getInstance()