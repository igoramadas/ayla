# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles home weather and climate conditions.
class WeatherManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    title: "Weather"

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

    # Init the weather manager.
    init: =>
        astronomy = {sunrise: "7:00", sunset: "18:00"}
        outdoor = getOutdoorObject "Outdoor"
        forecast = getOutdoorObject "Forecast"

        @baseInit {astronomy: astronomy, outdoor: outdoor, forecast: forecast}

    # Start the weather manager and listen to data updates / events.
    start: =>
        for key, room of settings.home.rooms
            if not @data[key]?
                @data[key] = getRoomObject room.title

        events.on "electricimp.data.current", @onElectricImp
        events.on "netatmo.data.indoor", @onNetatmoIndoor
        events.on "netatmo.data.outdoor", @onNetatmoOutdoor
        events.on "ninja.data.weather", @onNinjaWeather
        events.on "wunderground.data.astronomy", @onWundergroundAstronomy
        events.on "wunderground.data.current", @onWundergroundCurrent

        @baseStart()

    # Stop the weather manager.
    stop: =>
        events.off "electricimp.data.current", @onElectricImp
        events.off "netatmo.data.indoor", @onNetatmoIndoor
        events.off "netatmo.data.outdoor", @onNetatmoOutdoor
        events.off "ninja.data.weather", @onNinjaWeather
        events.off "wunderground.data.astronomy", @onWundergroundAstronomy
        events.off "wunderground.data.current", @onWundergroundCurrent

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
            if room.humidity > settings.home.idealConditions.humidity[3]
                room.condition = "Too humid"
                notifyOptions.critical = true
                notifyOptions.subject = "#{room.title} too humid"
                notifyOptions.message = "It's #{room.humidity}% right now, please open the windows immediately."
            else if room.humidity > settings.home.idealConditions.humidity[2]
                room.condition = "A bit humid"
                notifyOptions.subject =  "#{room.title} a bit humid"
                notifyOptions.message = "It's #{room.humidity}% right now, please open the windows."
            else if room.humidity < settings.home.idealConditions.humidity[1]
                room.condition = "A bit dry"
                notifyOptions.subject =  "#{room.title} a bit dry"
                notifyOptions.message = "It's #{room.humidity}% right now, please turn on the air humidifier."
            else if room.humidity < settings.home.idealConditions.humidity[0]
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
        return if not room?

        roomObj = @data[room]

        # Make sure data is taken out of the array and newer than current available data.
        if lodash.isArray data
            for d in data
                if d.timestamp > roomObj.timestamp
                    lastData = d
        else if data.timestamp > roomObj.timestamp
            lastData = data

        # Cancel here if data is not up-to-date.
        return if not lastData?

        # Update room data or set to null (otherwise it's undefined, not good for Knockout.js) and round values.
        roomObj.temperature = lastData.temperature or null
        roomObj.humidity = lastData.humidity or null
        roomObj.co2 = lastData.co2 or null
        roomObj.temperature = parseFloat(roomObj.temperature).toFixed 1 if roomObj.temperature?
        roomObj.humidity = parseFloat(roomObj.humidity).toFixed 1 if roomObj.humidity?

        # Check if room conditions are ok.
        @checkRoomWeather roomObj

        # Emit updated room conditions to clients and log.
        @dataUpdated room
        logger.info "WeatherManager.setRoomWeather", roomObj

    # Helper to set current conditions for outdoors.
    setOutdoorWeather: (data) =>
        @data.outdoor.temperature = data.temperature or null
        @data.outdoor.humidity = data.humidity or null

        # Emit updated outdoor conditions to clients and log.
        @dataUpdated "outdoor"
        logger.info "WeatherManager.setOutdoorWeather", @data.outdoor

    # Helper to set forecast conditions for outdoors.
    setWeatherForecast: (data) =>
        currentHour = moment().hour()
        sunriseHour = parseInt @data.astronomy.sunrise?.split(":")[0]
        sunsetHour = parseInt @data.astronomy.sunset?.split(":")[0]
        icon = data.icon.replace(".gif", "").replace("nt_", "")

        @data.forecast.condition = data.weather
        @data.forecast.temperature = data.temperature or data.temp_c or null
        @data.forecast.humidity = data.humidity or data.relative_humidity or null
        @data.forecast.pressure = data.pressure or data.pressure_mb or null

        # Set forecast icon.
        if "fog,hazy,cloudy,mostlycloudy".indexOf(icon) >= 0
            @data.forecast.icon = "cloud"
        else if "chancerain,rain,chancesleet,sleet".indexOf(icon) >= 0
            @data.forecast.icon = "rain"
        else if "chanceflurries,flurries,chancesnow,snow".indexOf(icon) >= 0
            @data.forecast.icon = "snow"
        else if "clear,sunny".indexOf(icon) >= 0
            @data.forecast.icon = "sunny"
        else if "mostlysunny,partlysunny,partlycloudy".indexOf(icon) >= 0
            @data.forecast.icon = "sunny-cloudy"
        else if "chancestorms,tstorms".indexOf(icon) >= 0
            @data.forecast.icon = "thunder"

        # Force moon icon when clear skies at night.
        if @data.forecast.icon.indexOf("sunny") >= 0 and currentHour < sunriseHour or currentHour > sunsetHour
            @data.forecast.icon = "moon"

        # Emit updated forecast to clients and log.
        @dataUpdated "forecast"
        logger.info "WeatherManager.setWeatherForecast", @data.forecast

    # Helper to set current astronomy details, like sunrise and moon phase.
    setAstronomy: (data) =>
        @data.astronomy.sunrise = "#{data.sunrise.hour}:#{data.sunrise.minute}"
        @data.astronomy.sunset = "#{data.sunset.hour}:#{data.sunset.minute}"
        @data.astronomy.moon = data.phaseofMoon

        # Emit astronomy data and log.
        @dataUpdated "astronomy"
        logger.info "WeatherManager.setAstronomy", @data.astronomy

    # Check indoor weather conditions using Netatmo.
    onNetatmoIndoor: (data, filter) =>
        if filter["module_id"]?
            source = {"netatmo": filter["module_id"]}
        else
            source = "netatmo"

        @setRoomWeather source, data

    # Check outdoor weather conditions using Netatmo.
    onNetatmoOutdoor: (data, filter) =>
        @setOutdoorWeather data

    # Check indoor weather conditions using Ninja Blocks.
    onNinjaWeather: (data, filter) =>
        weather = {}
        weather.temperature = data.temperature[0].value if data.temperature[0]?
        weather.humidity = data.humidity[0].value if data.humidity[0]?

        if weather.temperature? or weather.humidity?
            weather.timestamp = data.temperature[0].timestamp or data.humidity[0].timestamp

        @setRoomWeather "ninja", weather

    # Check indoor weather conditions using Electric Imp.
    onElectricImp: (data, filter) =>
        @setRoomWeather "electricimp", data

    # Check outdoor weather conditions using Weather Underground.
    onWundergroundCurrent: (data) =>
        @setWeatherForecast data

    # Check astronomy for today using Weather Underground.
    onWundergroundAstronomy: (data) =>
        @setAstronomy data

    # GENERAL HELPERS
    # -------------------------------------------------------------------------

    # Helper to get weather average readings.
    getWeatherAverage = (where, prop) =>
        avg = 0
        count = 0

        # Set properties to be read (indoor rooms or outdoor / forecast).
        if where is "indoor"
            arr = lodash.keys settings.home.rooms
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
        return {title: title, timestamp: 0, condition: "Unknown", temperature: null, humidity: null, pressure: null, co2: null, light: null}

    # Helper to return outdoor weather.
    getOutdoorObject = (title) =>
        return {title: title, timestamp: 0, condition: "Unknown", temperature: null, humidity: null, pressure: null}

# Singleton implementation.
# -----------------------------------------------------------------------------
WeatherManager.getInstance = ->
    @instance = new WeatherManager() if not @instance?
    return @instance

module.exports = exports = WeatherManager.getInstance()