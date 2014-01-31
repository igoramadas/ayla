# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles automatic messages, trigger events, etc based on API's data.
class HomeManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings
    sockets = expresser.sockets

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Computed weather stats.
    weatherAvgData: =>
        indoor = {}
        indoor.temperature = getWeatherAverage "indoor", "temperature"
        indoor.humidity = getWeatherAverage "indoor", "temperature"
        indoor.co2 = getWeatherAverage "indoor", "temperature"

        outdoor = {}
        outdoor.temperature = getWeatherAverage "outdoor", "temperature"
        outdoor.humidity = getWeatherAverage "outdoor", "humidity"

        return {indoor: indoor, outdoor: outdoor}

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

    # Start the home manager and listen to data updates / events.
    start: =>
        events.on "netamo.data.indoor", @onNetatmoIndoor
        events.on "netamo.data.outdoor", @onNetatmoOutdoor
        events.on "ninja.data.weather", @onNinjaWeather
        events.on "ubi.data.weather", @onUbiWeather
        events.on "wunderground.data.current", @onWunderground

        events.on "hue.data.hub", @onHueHub

        @baseStart()

    # Stop the home manager.
    stop: =>
        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to verify if room weather is in good condition.
    checkRoomWeather: (room) =>
        subject = "#{room.title} weather"

        if room.temperature > settings.home.temperature.max
            @notify subject, "#{room.title} too warm", "It's #{room.temperature}C right now, fan will turn on automatically."
        else if room.temperature < settings.home.temperature.min
            @notify subject, "#{room.title} too cold", "It's #{room.temperature}C right now, heating will turn on automatically."

    # Helper to set current conditions for the specified room.
    setRoomWeather: (room, data) =>
        roomObj = @data[room]
        roomObj.temperature = data.temperature
        roomObj.humidity = data.humidity
        roomObj.co2 = data.co2

        # Emit updated room conditions to clients and log.
        @emitData room
        logger.info "HomeManager.setRoomWeather", roomObj

        # Check if room conditions are ok.
        @checkRoomWeather room

    # Helper to set current conditions for outdoors.
    setOutdoorWeather: (data) =>
        @data.outdoor.temperature = data.temperature
        @data.outdoor.humidity = data.humidity

        # Emit updated outdoor conditions to clients and log.
        @emitData "outdoor"
        logger.info "HomeManager.setOutdoorWeather", @data.outdoor

    # Helper to set forecast conditions for outdoors.
    setWeatherForecast: (data) =>
        @data.forecast.text = data.weather
        @data.forecast.temperature = data.temperature or data.temp_c
        @data.forecast.humidity = data.humidity or data.relative_humidity
        @data.forecast.pressure = data.pressure or data.pressure_mb

        # Emit updated forecast to clients and log.
        @emitData "forecast"
        logger.info "HomeManager.setWeatherForecast", @data.forecast

    # Check indoor weather conditions using Netatmo.
    onNetatmoIndoor: (data) =>
        @setRoomWeather "livingroom", data.indoor

    # Check outdoor weather conditions using Netatmo.
    onNetatmoOutdoor: (data) =>
        @setOutdoorWeather data.outdoor

    # Check indoor weather conditions using Ninja Blocks.
    onNinjaWeather: (data) =>
        weather = {}
        weather.temperature = data.temperature[0].value if data.temperature.length > 0
        weather.humidity = data.humidity[0].value if data.humidity.length > 0

        @setRoomWeather "kitchen", weather

    # Check indoor weather conditions using The Ubi.
    onUbiWeather: (data) =>
        @setRoomWeather "bedroom", data

    # Check outdoor weather conditions using Weather Underground.
    onWunderground: (data) =>
        @setWeatherForecast data

    # LIGHTS
    # -------------------------------------------------------------------------

    # When Hue hub details are refreshed.
    onHueHub: (data) =>


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