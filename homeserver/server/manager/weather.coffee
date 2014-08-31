# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles home weather and climate conditions.
class WeatherManager extends (require "./basemanager.coffee")

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
        indoor.temperature = @getWeatherAverage "indoor", "temperature"
        indoor.humidity = @getWeatherAverage "indoor", "temperature"
        indoor.co2 = @getWeatherAverage "indoor", "temperature"

        outdoor = {}
        outdoor.temperature = @getWeatherAverage "outdoor", "temperature"
        outdoor.humidity = @getWeatherAverage "outdoor", "humidity"
        outdoor.rain = @getWeatherAverage "outdoor", "rain"

        return {indoor: indoor, outdoor: outdoor}

    # INIT
    # -------------------------------------------------------------------------

    # Init the weather manager.
    init: =>
        astronomy = {sunrise: "7:00", sunset: "18:00"}
        outdoor = getOutdoorObject "Outdoor"
        conditions = getOutdoorObject "Conditions"

        @baseInit {forecast: [], astronomy: astronomy, outdoor: outdoor, conditions: conditions, rooms: settings.home.rooms}

    # Start the weather manager and listen to data updates / events.
    # Indoor weather data depends on rooms being set on the settings.
    start: =>
        if not settings.home?.rooms?
            logger.warn "WeatherManager.start", "No rooms were defined on the settings. Indoor weather won't be monitored."
        else
            for room in settings.home.rooms
                @data[room.id] = getRoomObject room if not @data[room.id]?

        events.on "electricimp.data", @onElectricImp
        events.on "netatmo.data.indoor", @onNetatmoIndoor
        events.on "ninja.data.weather", @onNinjaWeather
        events.on "netatmo.data.outdoor", @onNetatmoOutdoor
        events.on "ubi.data.sensors", @onUbiSensors
        events.on "wunderground.data.astronomy", @onWundergroundAstronomy
        events.on "wunderground.data.conditions", @onWundergroundConditions
        events.on "wunderground.data.forecast", @onWundergroundForecast

        @baseStart()

    # Stop the weather manager.
    stop: =>
        events.off "electricimp.data", @onElectricImp
        events.off "netatmo.data.indoor", @onNetatmoIndoor
        events.off "netatmo.data.outdoor", @onNetatmoOutdoor
        events.off "ninja.data.weather", @onNinjaWeather
        events.off "ubi.data.sensors", @onUbiSensors
        events.off "wunderground.data.astronomy", @onWundergroundAstronomy
        events.off "wunderground.data.conditions", @onWundergroundConditions
        events.off "wunderground.data.forecast", @onWundergroundForecast

        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to verify if room weather is in good condition.
    checkRoomWeather: (room) =>
        conditions = []
        notifyOptions = {}

        # Check temperatures.
        if room.temperature?
            if room.temperature > settings.home.idealConditions.temperature[3]
                conditions.push "Too warm"
                notifyOptions.critical = true
                notifyOptions.subject = "#{room.title} too warm"
                notifyOptions.message = "It's #{room.temperature}C right now, ventilator will turn on automatically."
                @switchVentilator room.ventilatorSource, true, settings.home.ventilatorTimeout
            else if room.temperature > settings.home.idealConditions.temperature[2]
                conditions.push "A bit warm"
                notifyOptions.subject =  "#{room.title} is warm"
                notifyOptions.message = "It's #{room.temperature}C right now, please turn on the ventilator."
            else if room.temperature < settings.home.idealConditions.temperature[1]
                conditions.push "A bit cold"
                notifyOptions.subject =  "#{room.title} is cold"
                notifyOptions.message = "It's #{room.temperature}C right now, please turn on the heating."
            else if room.temperature < settings.home.idealConditions.temperature[0]
                conditions.push "Too cold"
                notifyOptions.critical = true
                notifyOptions.subject =  "#{room.title} too cold"
                notifyOptions.message = "It's #{room.temperature}C right now, please turn on the heating ASAP."

        # Check humidity.
        if room.humidity?
            if room.humidity > settings.home.idealConditions.humidity[3]
                conditions.push "Too humid"
                notifyOptions.critical = true
                notifyOptions.subject = "#{room.title} too humid"
                notifyOptions.message = "It's #{room.humidity}% right now, ventilator will turn on automatically."
                @switchVentilator room.ventilatorSource, true, settings.home.ventilatorTimeout
            else if room.humidity > settings.home.idealConditions.humidity[2]
                conditions.push "A bit humid"
                notifyOptions.subject =  "#{room.title} a bit humid"
                notifyOptions.message = "It's #{room.humidity}% right now, please open the windows."
            else if room.humidity < settings.home.idealConditions.humidity[1]
                conditions.push "A bit dry"
                notifyOptions.subject =  "#{room.title} a bit dry"
                notifyOptions.message = "It's #{room.humidity}% right now, please use the boiler to humidify the air."
            else if room.humidity < settings.home.idealConditions.humidity[0]
                conditions.push "Too dry"
                notifyOptions.critical = true
                notifyOptions.subject =  "#{room.title} too dry"
                notifyOptions.message = "It's #{room.humidity}% right now, please turn on the shower for some steam."

        # Check CO2.
        if room.co2?
            if room.co2 > settings.home.idealConditions.co2[3]
                conditions.push "CO2 too high"
                notifyOptions.critical = true
                notifyOptions.subject = "#{room.title} CO2 is too high"
                notifyOptions.message =  "With #{room.co2} ppm right now, please open the windows immediately."
            else if room.co2 > settings.home.idealConditions.co2[2]
                conditions.push "CO2 high"
                notifyOptions.subject = "#{room.title} CO2 is high"
                notifyOptions.message =  "With #{room.co2} ppm right now, please open the windows."

        # If no conditions were added, set condition as good.
        if conditions.length < 1
            room.condition = "Good"
        else
            room.condition = conditions.join ", "

        # Send notification?
        if notifyOptions.subject?
            @notify notifyOptions

    # Helper to set current conditions for the specified room.
    setRoomWeather: (source, data) =>
        return if not data?

        # Find room linked to the specified weather source.
        try
            roomObj = lodash.find @data, {weatherSource: source}
        catch ex
            logger.error "WeatherManager.setRoomWeather", source, data, ex.message
        return if not roomObj?

        # No room found? Abort here.
        if not roomObj?.id?
            logger.warn "WeatherManager.setRoomWeather", source, "Room not properly set, check settings.home.rooms and make sure they have an ID set."
            return

        # Make sure data is taken out of the array and newer than current available data.
        # Stop here if data is not up-to-date.
        lastData = @compareGetLastData data, roomObj
        return if not lastData?

        # Update room data or set to null (otherwise it's undefined, not good for Knockout.js) and round values.
        roomObj.temperature = lastData.temperature or lastData.temperature?[0]?.value or null
        roomObj.temperature = parseFloat(roomObj.temperature).toFixed 1 if roomObj.temperature?

        roomObj.humidity = lastData.humidity or lastData.humidity?[0]?.value  or null
        roomObj.humidity = parseFloat(roomObj.humidity).toFixed 1 if roomObj.humidity?
        roomObj.co2 = lastData.co2 or null
        roomObj.light = lastData.light or lastData.lightLevel or null

        # Set room data.
        @data[roomObj.id] = roomObj

        # Check if room conditions are ok.
        @checkRoomWeather roomObj

        # Emit updated room conditions to clients and log.
        @dataUpdated roomObj.id
        logger.info "WeatherManager.setRoomWeather", roomObj

    # Helper to set current conditions for outdoors.
    # Make sure data is taken out of the array and newer than current available data.
    setOutdoorWeather: (data) =>
        return if not data?

        # Make sure data is taken out of the array and newer than current available data.
        # Stop here if data is not up-to-date.
        lastData = @compareGetLastData data, @data.outdoor
        return if not lastData?

        # Updated outdoor data.
        outdoor = @data.outdoor
        outdoor.temperature = lastData.temperature or lastData.temp_c or outdoor.temperature
        outdoor.temperature = parseFloat(outdoor.temperature).toFixed 1 if outdoor.temperature?
        outdoor.humidity = lastData.humidity or lastData.relative_humidity or outdoor.humidity
        outdoor.humidity = parseFloat(outdoor.humidity).toFixed 1 if outdoor.humidity?
        outdoor.rain = lastData.rain or outdoor.rain
        outdoor.rain = parseFloat(outdoor.rain).toFixed 1 if outdoor.rain?

        # Emit updated outdoor conditions to clients and log.
        @dataUpdated "outdoor"
        logger.info "WeatherManager.setOutdoorWeather", outdoor

    # Helper to set current astronomy details, like sunrise and moon phase.
    setAstronomy: (data) =>
        @data.astronomy.sunrise = "#{data.value.sunrise.hour}:#{data.value.sunrise.minute}"
        @data.astronomy.sunset = "#{data.value.sunset.hour}:#{data.value.sunset.minute}"
        @data.astronomy.moon = data.value.phaseofMoon

        # Emit astronomy data and log.
        @dataUpdated "astronomy"
        logger.info "WeatherManager.setAstronomy", @data.astronomy

    # Helper to set expected conditions for outdoors.
    setWeatherConditions: (data) =>
        return if not data?

        @data.conditions.condition = data.value.weather
        @data.conditions.temperature = data.value.temperature or data.value.temp_c or null
        @data.conditions.humidity = data.value.humidity or data.value.relative_humidity or null
        @data.conditions.pressure = data.value.pressure or data.value.pressure_mb or null
        @data.conditions.wind = data.value.wind or "#{data.value.wind_dir} #{data.value.wind_kph}kph"
        @data.conditions.windSpeed = data.value.wind_kph or 0

        # Remove strings from data.
        @data.conditions.humidity = @data.conditions.humidity.replace("%", "") if @data.conditions.humidity?

        # Set conditions icon.
        @data.conditions.icon = @getWeatherIcon data.value.icon

        # Emit updated conditions to clients and log.
        @dataUpdated "conditions"
        logger.info "WeatherManager.setWeatherConditions", @data.conditions

    # Helper to set forecast details for the next days.
    setWeatherForecast: (data) =>
        @data.forecast = []

        for d in data.value.forecastday
            a = {date: moment.unix(d.date.epoch).format("L"), conditions: d.conditions}
            a.highTemp = d.high.celsius
            a.lowTemp = d.low.celsius
            a.avgWind = d.avewind.dir + " " + d.avewind.kph + "kph"
            a.maxWind = d.maxwind.dir + " " + d.maxwind.kph + "kph"
            a.avgHumidity = d.avehumidity
            a.maxHumidity = d.maxhumidity
            a.minHumidity = d.minhumidity
            a.icon = @getWeatherIcon d.icon

            # Set the friendly date string.
            if a.date is moment().format("L")
                a.dateString = "Today"
            else if a.date is moment().add(1, "d").format("L")
                a.dateString = "Tomorrow"
            else
                a.dateString = a.date

            @data.forecast.push a

        # Emit forecast dat and log.
        @dataUpdated "forecast"
        logger.info "WeatherManager.setWeatherForecast", @data.forecast

    # Check indoor weather conditions using Netatmo.
    onNetatmoIndoor: (data, filter) =>
        if filter["module_id"]?
            source = {"netatmo": filter["module_id"]}
        else
            source = {"netatmo": ""}

        @setRoomWeather source, data

    # Check outdoor weather conditions using Netatmo.
    onNetatmoOutdoor: (data, filter) =>
        @setOutdoorWeather data

    # Check indoor weather conditions using Ninja Blocks.
    onNinjaWeather: (data, filter) =>
        weather = {}
        weather.temperature = data.value.temperature[0].value if data.value.temperature[0]?
        weather.humidity = data.value.humidity[0].value if data.value.humidity[0]?

        if weather.temperature? or weather.humidity?
            weather.timestamp = data.value.temperature[0].timestamp or data.value.humidity[0].timestamp

        # Update original data and set room weather.
        data.value = weather
        @setRoomWeather {"ninja": ""}, data

    # Check indoor weather conditions using Electric Imp. We're binding to the global data event,
    # so a key is passed here as well.
    onElectricImp: (key, data, filter) =>
        @setRoomWeather {"electricimp": key}, data

    # Check sensor data from Ubi.
    onUbiSensors: (data, filter) =>
        @setRoomWeather {"ubi": data.value.device_id}, data

    # Check astronomy for today using Weather Underground.
    onWundergroundAstronomy: (data) =>
        @setAstronomy data

    # Check outdoor weather conditions using Weather Underground.
    onWundergroundConditions: (data) =>
        @setWeatherConditions data

    # Check outdoor weather forecast for next days using Weather Underground.
    onWundergroundForecast: (data) =>
        @setWeatherForecast data

    # WEATHER MAINTENANCE
    # -------------------------------------------------------------------------

    # Turn the specified ventilator ON or OFF. Supports ninja blocks, using the
    # format {ninja: {on: "433_ID_ON", off: "433_ID_OFF"}}
    switchVentilator: (source, onOrOff, timeoutMinutes) =>
        return if not source?.ninja?

        logger.info "WeatherManager.switchVentilator", source, onOrOff, timeoutMinutes

        # Actuate correct Ninja device depending if on or off.
        if onOrOff
            events.emit "ninja.actuate433", {id: source.ninja.on}
        else
            events.emit "ninja.actuate433", {id: source.ninja.off}

        # Turn off automatically after timeout, if specified.
        # Convert timeout to milliseconds.
        if timeoutMinutes? and timeoutMinutes > 0 and onOrOff
            timeoutMinutes = timeoutMinutes * 60000
            lodash.delay events.emit, timeoutMinutes, "ninja.actuate433", {id: source.ninja.off}

    # GENERAL GET HELPERS
    # -------------------------------------------------------------------------

    # Helper to get weather average readings.
    getWeatherAverage: (where, prop) =>
        avg = 0
        count = 0

        # Set properties to be read (indoor rooms or outdoor / conditions).
        if where is "indoor"
            arr = lodash.pluck settings.home.rooms, "id"
        else
            arr = ["outdoor", "conditions"]

        # Iterate readings.
        for r in arr
            if @data[r][prop]?
                avg += @data[r][prop]
                count += 1

        # Return average reading for the specified property.
        return avg / count

    # Helper to get correct weather icon. Default is sunny / cloudy.
    getWeatherIcon: (icon) =>
        result = "sunny-cloudy"

        currentHour = moment().hour()
        sunriseHour = parseInt @data.astronomy.sunrise?.split(":")[0]
        sunsetHour = parseInt @data.astronomy.sunset?.split(":")[0]

        icon = icon.replace(".gif", "").replace("nt_", "")

        if "fog,hazy,cloudy,mostlycloudy".indexOf(icon) >= 0
            result = "cloud"
        else if "chancerain,rain,chancesleet,sleet".indexOf(icon) >= 0
            result = "rain"
        else if "chanceflurries,flurries,chancesnow,snow".indexOf(icon) >= 0
            result = "snow"
        else if "clear,sunny".indexOf(icon) >= 0
            result = "sunny"
        else if "chancestorms,tstorms".indexOf(icon) >= 0
            result = "thunder"

        # Force moon icon when clear skies at night.
        if icon.indexOf("sunny") >= 0 and currentHour < sunriseHour or currentHour > sunsetHour
            result = "moon"

        return result

    # Helper to return room object with weather, title etc.
    getRoomObject = (room) =>
        obj = lodash.clone room
        obj = lodash.assign obj, {timestamp: 0, condition: "Unknown", temperature: null, humidity: null, pressure: null, co2: null, light: null}
        return obj

    # Helper to return outdoor weather.
    getOutdoorObject = (title) =>
        return {outdoor: true, title: title, timestamp: 0, condition: "Unknown", temperature: null, humidity: null, pressure: null}

# Singleton implementation.
# -----------------------------------------------------------------------------
WeatherManager.getInstance = ->
    @instance = new WeatherManager() if not @instance?
    return @instance

module.exports = exports = WeatherManager.getInstance()
