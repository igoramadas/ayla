# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles home lights (Philips Hue and RF sockets).
class LightsManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings
    sockets = expresser.sockets

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # INIT
    # -------------------------------------------------------------------------

    # Init the lights manager.
    init: =>
        @data.hue = []
        @baseInit()

    # Start the lights manager and listen to data updates / events.
    start: =>
        events.on "hue.data.hub", @onHueHub

        @baseStart()

    # Stop the lights manager.
    stop: =>
        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to verify if room weather is in good condition.
    checkRoomWeather: (room) =>
        room.condition = "Good"
        notifyOptions = {}

        # Check temperatures.
        if room.temperature?
            if room.temperature > settings.home.idealConditions.temperature[3]
                room.condition = "Too warm"
                notifyOptions.critical = true
                notifyOptions.subject = "#{room.title} too warm"
                notifyOptions.message = "It's #{room.temperature}C right now, fans will turn on automatically."
            else if room.temperature > settings.home.idealConditions.temperature[2]
                room.condition = "A bit warm"
                notifyOptions.subject =  "#{room.title} is warm"
                notifyOptions.message = "It's #{room.temperature}C right now, please turn in the fans."
            else if room.temperature < settings.home.idealConditions.temperature[1]
                room.condition = "A bit cold"
                notifyOptions.subject =  "#{room.title} is cold"
                notifyOptions.message = "It's #{room.temperature}C right now, please turn on the heating."
            else if room.temperature < settings.home.idealConditions.temperature[0]
                room.condition = "Too cold"
                notifyOptions.critical = true
                notifyOptions.subject =  "#{room.title} too cold"
                notifyOptions.message = "It's #{room.temperature}C right now, heating will turn on automatically."

        # Check humidity.
        if room.humidity?
            if room.temperature > settings.home.idealConditions.humidity[3]
                room.condition = "Too humid"
                notifyOptions.critical = true
                notifyOptions.subject = "#{room.title} too humid"
                notifyOptions.message = "It's #{room.humidity}% right now, please open the windows immediately."
            else if room.temperature > settings.home.idealConditions.humidity[2]
                room.condition = "A bit humid"
                notifyOptions.subject =  "#{room.title} a bit humid"
                notifyOptions.message = "It's #{room.humidity}% right now, please open the windows."
            else if room.temperature < settings.home.idealConditions.humidity[1]
                room.condition = "A bit dry"
                notifyOptions.subject =  "#{room.title} a bit dry"
                notifyOptions.message = "It's #{room.humidity}% right now, please turn on the air humidifier."
            else if room.temperature < settings.home.idealConditions.humidity[0]
                room.condition = "Too dry"
                notifyOptions.critical = true
                notifyOptions.subject =  "#{room.title} too dry"
                notifyOptions.message = "It's #{room.humidity}% right now, please turn on the shower for some steam."

        # Check CO2.
        if room.co2?
            if room.co2 > settings.home.idealConditions.co2[23]
                room.condition = "CO2 too high"
                notifyOptions.critical = true
                notifyOptions.subject = "#{room.title} CO2 is too high"
                notifyOptions.message =  "With #{room.co2} ppm right now, please open the windows immediately."
            else if room.co2 > settings.home.idealConditions.co2[23]
                room.condition = "CO2 high"
                notifyOptions.subject = "#{room.title} CO2 is high"
                notifyOptions.message =  "With #{room.co2} ppm right now, please open the windows."

        # Send notification?
        if notifyOptions.subject?
            @notify notifyOptions

    # Helper to set current conditions for the specified room.
    setRoomWeather: (source, data) =>
        room = lodash.findKey settings.home.rooms, {weatherSource: source}

        roomObj = @data[room]
        roomObj.temperature = data.temperature or null
        roomObj.humidity = data.humidity or null
        roomObj.co2 = data.co2 or null

        # Round values.
        roomObj.temperature = parseFloat(roomObj.temperature).toFixed 1 if roomObj.temperature?
        roomObj.humidity = parseFloat(roomObj.humidity).toFixed 1 if roomObj.humidity?

        # Check if room conditions are ok.
        @checkRoomWeather roomObj

        # Emit updated room conditions to clients and log.
        @dataUpdated room
        logger.info "LightsManager.setRoomWeather", roomObj

    # Helper to set current conditions for outdoors.
    setOutdoorWeather: (data) =>
        @data.outdoor.temperature = data.temperature
        @data.outdoor.humidity = data.humidity

        # Emit updated outdoor conditions to clients and log.
        @dataUpdated "outdoor"
        logger.info "LightsManager.setOutdoorWeather", @data.outdoor

    # Helper to set forecast conditions for outdoors.
    setWeatherForecast: (data) =>
        @data.forecast.condition = data.weather
        @data.forecast.temperature = data.temperature or data.temp_c
        @data.forecast.humidity = data.humidity or data.relative_humidity
        @data.forecast.pressure = data.pressure or data.pressure_mb

        # Emit updated forecast to clients and log.
        @dataUpdated "forecast"
        logger.info "LightsManager.setWeatherForecast", @data.forecast

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
                state = {on: lightData.state.on, color: getHueHex lightData.state}
                groupData.lights.push {id: lightId, name: lightData.name, state: state}

        # Emit updated lights and save log.
        @dataUpdated "hue"
        logger.info "LightsManager.onHueHub", @data.hue

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

    # Helper to get HEX color from a hue light state.
    getHueHex = (state) ->
        x = state.xy[0]
        y = state.xy[1]
        z = 1.0 - x - y
        Y = state.bri
        X = (Y / y) * x
        Z = (Y / y) * z
        r = X * 1.612 - Y * 0.203 - Z * 0.302
        g = -X * 0.509 + Y * 1.412 + Z * 0.066
        b = X * 0.026 - Y * 0.072 + Z * 0.962
        r = (if r <= 0.0031308 then 12.92 * r else (1.0 + 0.055) * Math.pow(r, (1.0 / 2.4)) - 0.055)
        g = (if g <= 0.0031308 then 12.92 * g else (1.0 + 0.055) * Math.pow(g, (1.0 / 2.4)) - 0.055)
        b = (if b <= 0.0031308 then 12.92 * b else (1.0 + 0.055) * Math.pow(b, (1.0 / 2.4)) - 0.055)
        cap = (x) -> Math.max 0, Math.min(1, x)

        # Helper to convert RGB to hex.
        rgbhex = (v) ->
            v = Math.round(v * 255)
            s = "0" + v.toString(16)
            return s.substr -2

        # Cap and transform RGB values.
        r = rgbhex cap r
        g = rgbhex cap g
        b = rgbhex cap b

        # Convert RGB to hex and return result.
        return "##{r}#{g}#{b}"

# Singleton implementation.
# -----------------------------------------------------------------------------
LightsManager.getInstance = ->
    @instance = new LightsManager() if not @instance?
    return @instance

module.exports = exports = LightsManager.getInstance()