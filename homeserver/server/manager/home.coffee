# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles automatic messages, trigger events, etc based on API's data.
class HomeManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings

    # COMPUTED PROPERTIES
    # -------------------------------------------------------------------------

    # Computed weather stats.
    weather:
        indoor:
            temperature: -> return getWeatherAverage "indoor", "temperature"
            humidity: -> return getWeatherAverage "indoor", "temperature"
            co2: -> return getWeatherAverage "indoor", "temperature"
        outdoor:
            temperature: -> return getWeatherAverage "outdoor", "temperature"
            humidity: -> return getWeatherAverage "outdoor", "humidity"

    # INIT
    # -------------------------------------------------------------------------

    # Init the home manager.
    init: =>
        @data.bedroom = getRoomObject "Bedroom"
        @data.livingroom = getRoomObject "Living Room"
        @data.babyroom = getRoomObject "Noah's room"
        @data.kitchen = getRoomObject "Kitchen"
        @data.outdoor = {}
        @data.forecast = {}

        @baseInit()

    # Start the home manager and listen to data updates.
    start: =>
        events.on "netamo.data.indoor", @onNetatmoIndoor
        events.on "netamo.data.outdoor", @onNetatmoOutdoor
        events.on "ninja.data.weather", @onNinjaWeather
        events.on "ubi.data.weather", @onUbiWeather
        events.on "wunderground.data", @onWunderground

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

    # Helper to set forecast conditions for outdoors.
    setWeatherForecast: (data) =>
        outdoorObj = @data[room]
        outdoorObj.temperature = data.temperature
        outdoorObj.humidity = data.humidity

    # Check indoor weather conditions using Netatmo.
    onNetatmoIndoor: (data) =>
        @setRoomWeather "livingroom", data.indoor

    # Check outdoor weather conditions using Netatmo.
    onNetatmoOutdoor: (data) =>
        @setOutdoorWeather data.outdoor

    # Check indoor weather conditions using Ninja Blocks.
    onNinjaWeather: (data) =>
        @setRoomWeather "kitchen", data.weather

    # Check indoor weather conditions using The Ubi.
    onUbiWeather: (data) =>
        @setRoomWeather "bedroom", data.weather

    # Check outdoor weather conditions using Weather Underground.
    onWunderground: (data) =>
        @setWeatherForecast data.today

    # GENERAL HELPERS
    # -------------------------------------------------------------------------

    # Helper to get weather average readings.
    getWeatherAverage = (where, prop) =>
        avg = 0
        count = 0

        # Set properties to be read (indoor rooms or outdoor / forecast).
        if where is "indoor"
            arr = ["bedroom", "livingroom", "babyroom", "kitchen"]
        else
            arr = ["outdoor", "forecast"]

        # Iterate readings.
        for r in arr
            if @data[r][prop]?
                avg += @data[r][prop]
                count += 1

        # Return average reading for the specified property.
        return avg / count

    # Helper to return room object with weather, title etc.
    getRoomObject = (title) =>
        weather = {temperature: null, humidity: null, co2: null}
        return {title: title, weather: weather}


# Singleton implementation.
# -----------------------------------------------------------------------------
HomeManager.getInstance = ->
    @instance = new HomeManager() if not @instance?
    return @instance

module.exports = exports = HomeManager.getInstance()