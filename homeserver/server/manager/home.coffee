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

    lodash = require "lodash"
    moment = require "moment"

    # COMPUTED PROPERTIES
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
        @data.outdoor = getOutdoorObject "Outdoor"
        @data.forecast = getOutdoorObject "Forecast"

        # Set rooms.
        for key, room of settings.home.rooms
            @data[key] = getRoomObject room.title

        # Set hue.
        @data.hue = []

        @baseInit()

    # Start the home manager and listen to data updates / events.
    start: =>
        events.on "electricimp.data.current", @onElectricImp
        events.on "hue.data.hub", @onHueHub
        events.on "netatmo.data.indoor", @onNetatmoIndoor
        events.on "netatmo.data.outdoor", @onNetatmoOutdoor
        events.on "ninja.data.weather", @onNinjaWeather
        events.on "wunderground.data.current", @onWunderground

        @baseStart()

    # Stop the home manager.
    stop: =>
        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to verify if room weather is in good condition.
    checkRoomWeather: (room) =>
        room.condition = "Good"

        # Check temperatures.
        if room.temperature?
            if room.temperature > settings.home.idealConditions.temperature[2]
                room.condition = "Too warm"
                @notify "#{room.title} too warm", "It's #{room.temperature}C right now, fan will turn on automatically."
            else if room.temperature < settings.home.idealConditions.temperature[0]
                room.condition = "Too cold"
                @notify "#{room.title} too cold", "It's #{room.temperature}C right now, heating will turn on automatically."

        # Check humidity.
        if room.humidity?
            if room.humidity > settings.home.idealConditions.humidity[2]
                room.condition = "Too humid"
                @notify "#{room.title} too humid", "It's #{room.humidity}% right now, please boil some water at the kitchen."
            else if room.humidity < settings.home.idealConditions.humidity[0]
                room.condition = "Too dry"
                @notify "#{room.title} too dry", "It's #{room.humidity}% right now, please open the windows."

        # Check CO2.
        if room.co2? and room.co2 > settings.home.idealConditions.co2[2]
            room.condition = "Too much CO2"
            @notify "#{room.title} has too much CO2", "With #{room.co2}C right now, please open the windows."

    # Helper to set current conditions for the specified room.
    setRoomWeather: (source, data) =>
        room = lodash.findKey settings.home.rooms, {weatherSource: source}

        roomObj = @data[room]
        roomObj.temperature = data.temperature or null
        roomObj.humidity = data.humidity or null
        roomObj.co2 = data.co2 or null

        # Check if room conditions are ok.
        @checkRoomWeather roomObj

        # Emit updated room conditions to clients and log.
        @dataUpdated room
        logger.info "HomeManager.setRoomWeather", roomObj

    # Helper to set current conditions for outdoors.
    setOutdoorWeather: (data) =>
        @data.outdoor.temperature = data.temperature
        @data.outdoor.humidity = data.humidity

        # Emit updated outdoor conditions to clients and log.
        @dataUpdated "outdoor"
        logger.info "HomeManager.setOutdoorWeather", @data.outdoor

    # Helper to set forecast conditions for outdoors.
    setWeatherForecast: (data) =>
        @data.forecast.condition = data.weather
        @data.forecast.temperature = data.temperature or data.temp_c
        @data.forecast.humidity = data.humidity or data.relative_humidity
        @data.forecast.pressure = data.pressure or data.pressure_mb

        # Emit updated forecast to clients and log.
        @dataUpdated "forecast"
        logger.info "HomeManager.setWeatherForecast", @data.forecast

    # Check indoor weather conditions using Netatmo.
    onNetatmoIndoor: (data) =>
        @setRoomWeather "netatmo", data

    # Check outdoor weather conditions using Netatmo.
    onNetatmoOutdoor: (data) =>
        @setOutdoorWeather data

    # Check indoor weather conditions using Ninja Blocks.
    onNinjaWeather: (data) =>
        weather = {}
        weather.temperature = data.temperature[0].value if data.temperature[0]?
        weather.humidity = data.humidity[0].value if data.humidity[0]?

        @setRoomWeather "ninja", weather

    # Check indoor weather conditions using Electric Imp.
    onElectricImp: (data) =>
        @setRoomWeather "electricimp", data

    # Check outdoor weather conditions using Weather Underground.
    onWunderground: (data) =>
        @setWeatherForecast data

    # LIGHTS
    # -------------------------------------------------------------------------

    # Update hue lights and groups.
    onHueHub: (data) =>
        @data.hue = []

        # Iterate groups.
        for groupId, group of data.groups
            groupData = {id: groupId, room: group.name, lights: []}
            @data.hue.push groupData

            # Iterate group lights.
            for lightId in group.lights
                lightData = data.lights[lightId]
                groupData.lights.push {id: lightId, name: lightData.name, state: lightData.state}

        # Emit updated lights and save log.
        @dataUpdated "hue"
        logger.info "HomeManager.onHueHub", @data.hue

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
        return {title: title, condition: "OK", temperature: null, humidity: null, pressure: null, co2: null, light: null}

    # Helper to return outdoor weather.
    getOutdoorObject = (title) =>
        return {title: title, condition: "OK", temperature: null, humidity: null, pressure: null}


# Singleton implementation.
# -----------------------------------------------------------------------------
HomeManager.getInstance = ->
    @instance = new HomeManager() if not @instance?
    return @instance

module.exports = exports = HomeManager.getInstance()