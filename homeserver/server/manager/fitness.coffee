# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles fitness data (sleep, weight, fat, activities etc).
class FitnessManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # COMPUTED PROPERTIES
    # -------------------------------------------------------------------------

    # Computed fitness stats.
    fitnessAvgData: =>
        indoor = {}
        indoor.temperature = getFitnessAverage "indoor", "temperature"
        indoor.humidity = getFitnessAverage "indoor", "temperature"
        indoor.co2 = getFitnessAverage "indoor", "temperature"

        outdoor = {}
        outdoor.temperature = getFitnessAverage "outdoor", "temperature"
        outdoor.humidity = getFitnessAverage "outdoor", "humidity"

        return {indoor: indoor, outdoor: outdoor}

    # INIT
    # -------------------------------------------------------------------------

    # Init the fitness manager.
    init: =>
        astronomy = {sunrise: "7:00", sunset: "18:00"}
        outdoor = getOutdoorObject "Outdoor"
        forecast = getOutdoorObject "Forecast"

        @baseInit {astronomy: astronomy, outdoor: outdoor, forecast: forecast}

    # Start the fitness manager and listen to data updates / events.
    start: =>
        for key, room of settings.home.rooms
            if not @data[key]?
                @data[key] = getRoomObject room.title

        events.on "electricimp.data.current", @onElectricImp
        events.on "netatmo.data.indoor", @onNetatmoIndoor
        events.on "netatmo.data.outdoor", @onNetatmoOutdoor
        events.on "ninja.data.fitness", @onNinjaFitness
        events.on "wunderground.data.astronomy", @onWundergroundAstronomy
        events.on "wunderground.data.current", @onWundergroundCurrent

        @baseStart()

    # Stop the fitness manager.
    stop: =>
        events.off "electricimp.data.current", @onElectricImp
        events.off "netatmo.data.indoor", @onNetatmoIndoor
        events.off "netatmo.data.outdoor", @onNetatmoOutdoor
        events.off "ninja.data.fitness", @onNinjaFitness
        events.off "wunderground.data.astronomy", @onWundergroundAstronomy
        events.off "wunderground.data.current", @onWundergroundCurrent

        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to verify if room fitness is in good condition.
    checkRoomFitness: (room) =>
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
    setRoomFitness: (source, data) =>
        room = lodash.findKey settings.home.rooms, {fitnessSource: source}

        roomObj = @data[room]
        roomObj.temperature = data.temperature or null
        roomObj.humidity = data.humidity or null
        roomObj.co2 = data.co2 or null

        # Round values.
        roomObj.temperature = parseFloat(roomObj.temperature).toFixed 1 if roomObj.temperature?
        roomObj.humidity = parseFloat(roomObj.humidity).toFixed 1 if roomObj.humidity?

        # Check if room conditions are ok.
        @checkRoomFitness roomObj

        # Emit updated room conditions to clients and log.
        @dataUpdated room
        logger.info "FitnessManager.setRoomFitness", roomObj

    # Helper to set current conditions for outdoors.
    setOutdoorFitness: (data) =>
        @data.outdoor.temperature = data.temperature
        @data.outdoor.humidity = data.humidity

        # Emit updated outdoor conditions to clients and log.
        @dataUpdated "outdoor"
        logger.info "FitnessManager.setOutdoorFitness", @data.outdoor

    # Helper to set forecast conditions for outdoors.
    setFitnessForecast: (data) =>
        currentHour = moment().hour()
        sunriseHour = parseInt @data.astronomy.sunrise?.split(":")[0]
        sunsetHour = parseInt @data.astronomy.sunset?.split(":")[0]
        icon = data.icon.replace(".gif", "").replace("nt_", "")

        @data.forecast.condition = data.fitness
        @data.forecast.temperature = data.temperature or data.temp_c
        @data.forecast.humidity = data.humidity or data.relative_humidity
        @data.forecast.pressure = data.pressure or data.pressure_mb

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
        logger.info "FitnessManager.setFitnessForecast", @data.forecast

    # Helper to set current astronomy details, like sunrise and moon phase.
    setAstronomy: (data) =>
        @data.astronomy.sunrise = "#{data.sunrise.hour}:#{data.sunrise.minute}"
        @data.astronomy.sunset = "#{data.sunset.hour}:#{data.sunset.minute}"
        @data.astronomy.moon = data.phaseofMoon

        # Emit astronomy data and log.
        @dataUpdated "astronomy"
        logger.info "FitnessManager.setAstronomy", @data.astronomy

    # Check indoor fitness conditions using Netatmo.
    onNetatmoIndoor: (data) =>
        @setRoomFitness "netatmo", data

    # Check outdoor fitness conditions using Netatmo.
    onNetatmoOutdoor: (data) =>
        @setOutdoorFitness data

    # Check indoor fitness conditions using Ninja Blocks.
    onNinjaFitness: (data) =>
        fitness = {}
        fitness.temperature = data.temperature[0].value if data.temperature[0]?
        fitness.humidity = data.humidity[0].value if data.humidity[0]?

        @setRoomFitness "ninja", fitness

    # Check indoor fitness conditions using Electric Imp.
    onElectricImp: (data) =>
        @setRoomFitness "electricimp", data

    # Check outdoor fitness conditions using Fitness Underground.
    onWundergroundCurrent: (data) =>
        @setFitnessForecast data

    # Check astronomy for today using Fitness Underground.
    onWundergroundAstronomy: (data) =>
        @setAstronomy data

    # GENERAL HELPERS
    # -------------------------------------------------------------------------

    # Helper to get fitness average readings.
    getFitnessAverage = (where, prop) =>
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

    # Helper to return room object with fitness, title etc.
    getRoomObject = (title) =>
        return {title: title, condition: "Unknown", temperature: null, humidity: null, pressure: null, co2: null, light: null}

    # Helper to return outdoor fitness.
    getOutdoorObject = (title) =>
        return {title: title, condition: "Unknown", temperature: null, humidity: null, pressure: null}

# Singleton implementation.
# -----------------------------------------------------------------------------
FitnessManager.getInstance = ->
    @instance = new FitnessManager() if not @instance?
    return @instance

module.exports = exports = FitnessManager.getInstance()