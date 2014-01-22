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

    # Init the home manager.
    init: =>
        @data.bedroom = getRoomObject "Bedroom"
        @data.livingroom = getRoomObject "Living Room"
        @data.babyroom = getRoomObject "Noah's room"
        @data.kitchen = getRoomObject "Kitchen"

        @baseInit()

    # Start the home manager and listen to data updates.
    start: =>
        events.on "netamo.data.indoor", @onNetatmoIndoor
        events.on "netamo.data.outdoor", @onNetatmoOutdoor
        events.on "ninja.data.weather", @onNinja
        events.on "ubi.data.weather", @onUbi
        events.on "withings.data.weather", @onWithings
        events.on "wunderground.data", @onWithings

        @baseStart()

    # Stop the home manager.
    stop: =>
        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to verify if room weather is in good condition.
    checkRoomWeather: (room) =>
        if room.temperature > settings.home.temperature.max
            @notify
        else if room.temperature < settings.home.temperature.min
            @notify

    # Helper to set current conditions for the specified room.
    setRoomWeather: (room, data) =>
        roomObj = @data[room]
        roomObj.temperature = data.temperature
        roomObj.humidity = data.humidity
        roomObj.co2 = data.co2

        @checkRoomWeather room

    # Helper to set current conditions for outdoors.
    setOutdoorWeather: (data) =>
        outdoorObj = @data[room]
        outdoorObj.temperature = data.temperature
        outdoorObj.humidity = data.humidity

    # Check home indoor conditions using Netatmo.
    onNetatmoIndoor: (data) =>
        @setRoomWeather "livingroom", netatmo.data.indoor

    # CHeck outdoor conditions using Netatmo.
    onNetatmoOutdoor: (data) =>
        @setOutdoorWeather netatmo.data.outdoor

    # GENERAL HELPERS
    # -------------------------------------------------------------------------

    # Helper to return room object with weather, title etc.
    getRoomObject = (title) ->
        weather = {temperature: null, humidity: null, co2: null}
        return {title: title, weather: weather}


# Singleton implementation.
# -----------------------------------------------------------------------------
HomeManager.getInstance = ->
    @instance = new HomeManager() if not @instance?
    return @instance

module.exports = exports = HomeManager.getInstance()