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
    init: =>
        @data.bedRoom = getRoomObject "Bedroom"
        @data.livingRoom = getRoomObject "Living Room"
        @data.babyRoom = getRoomObject "Noah's room"
        @data.kitchen = getRoomObject "Kitchen"

    # Start the home manager.
    start: =>
        events.on "netamo.data.indoor", @onNetatmoIndoor
        events.on "netamo.data.outdoor", @onNetatmoOutdoor

        @baseStart()

    # Stop the home manager.
    stop: =>
        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to return room object with weather, title etc.
    getRoomObject = (title) ->
        weather = {temperature: 0, humidity: 0, co2: 0}
        return {title: title, weather: weather}

    # Check home indoor conditions.
    onNetatmoIndoor: (data) =>
        alerts = []

        if netatmo.data.indoor.temperature < settings.home.temperature.min

            @alertIndoor 1

    onNetatmoOutdoor: (data) =>



# Singleton implementation.
# -----------------------------------------------------------------------------
HomeManager.getInstance = ->
    @instance = new HomeManager() if not @instance?
    return @instance

module.exports = exports = HomeManager.getInstance()