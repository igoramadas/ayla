# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles automatic messages, trigger events, etc based on API's data.
class HomeManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings

    netatmo = require "../api/netatmo.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init the manager and start listeting to data updates.
    init: (callback) =>
        events.on "netamo.data.indoor", @checkIndoorWeather

        callback() if callback?

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Check home indoor conditions.
    checkIndoorWeather: =>
        alerts = []

        if netatmo.data.indoor.temperature < settings.home.temperature.min

        @alertIndoor

    alertIndoor: (data) =>



# Singleton implementation.
# -----------------------------------------------------------------------------
HomeManager.getInstance = ->
    @instance = new HomeManager() if not @instance?
    return @instance

module.exports = exports = HomeManager.getInstance()