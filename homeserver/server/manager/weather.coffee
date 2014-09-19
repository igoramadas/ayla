# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles home weather and climate conditions.
class WeatherManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    climateModel = require "../model/climate.coffee"
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    roomModel = require "../model/room.coffee"
    settings = expresser.settings
    sockets = expresser.sockets

    title: "Weather"

    # INIT
    # -------------------------------------------------------------------------

    # Init the weather manager with the default values.
    init: =>
        astronomy = {sunrise: "7:00", sunset: "18:00"}
        outside = new climateModel {title: "Outdoor"}
        conditions = new climateModel {title: "Conditions"}

        @baseInit {forecast: [], astronomy: astronomy, outside: outside, conditions: conditions, rooms: settings.home.rooms}

    # Start the weather manager and listen to data updates / events.
    # Indoor weather data depends on rooms being set on the settings.
    start: =>
        if not settings.home?.rooms?
            logger.warn "WeatherManager.start", "No rooms were defined on the settings. Indoor weather won't be monitored."
        else
            for room in settings.home.rooms
                @data[room.id] = new roomModel(room) if not @data[room.id]?

        events.on "ElectricImp.data", @onElectricImp
        events.on "Netatmo.data", @onNetatmo
        events.on "Ninja.data", @onNinja
        events.on "Ubi.data", @onUbi
        events.on "Wunderground.data", @onWunderground

        @baseStart()

    # Stop the weather manager.
    stop: =>
        events.off "ElectricImp.data", @onElectricImp
        events.off "Netatmo.data", @onNetatmo
        events.off "Ninja.data", @onNinja
        events.off "Ubi.data", @onUbi
        events.off "Wunderground.data", @onWunderground

        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to verify if room climate is in good condition. Do necessary actions
    # and notify if it's not.
    checkRoomClimate: (room) =>
        return if not room.climate?

        notifyOptions = {}
        condition = room.climate.condition.toLowerCase()

        # Check temperature.
        if condition.indexOf("too warm") >= 0
            notifyOptions.critical = true
            @switchVentilator room.ventilatorSource, true, settings.home.ventilatorTimeout
        else if condition.indexOf("too cold") >= 0
            notifyOptions.critical = true

        # Check humidity.
        if condition.indexOf("too humid") >= 0
            notifyOptions.critical = true
            @switchVentilator room.ventilatorSource, true, settings.home.ventilatorTimeout
        else if condition.indexOf("too dry") >= 0
            notifyOptions.critical = true

        # Check CO2.
        if condition.indexOf("co2 too high") >= 0
            notifyOptions.critical = true

        # Alert about bad room conditions.
        if condition isnt "good"
            notifyOptions.subject = "#{room.title}: #{room.climate.condition}"
            notifyOptions.message =  "Conditions: temperature #{room.climate.temperature}, humidity #{room.climate.humidity}, CO2 #{room.climate.co2}."

            @notify notifyOptions

    # Helper to set current conditions for the specified room.
    setRoomClimate: (data, source) =>
        return if not data?

        # Find room linked to the specified weather source.
        try
            roomObj = lodash.find @data, {climateSource: source}
        catch ex
            logger.error "WeatherManager.setRoomClimate", source, data, ex.message
        return if not roomObj?

        # No room found? Abort here.
        if not roomObj?.id?
            logger.warn "WeatherManager.setRoomClimate", source, "Room not properly set, check settings.home.rooms and make sure they have an ID set."
            return

        # Make sure data is taken out of the array and newer than current available data.
        # Stop here if data is not up-to-date.
        lastData = @compareGetLastData data, roomObj
        return if not lastData?

        # Set room data and check its climate.
        @data[roomObj.id].setData lastData
        @checkRoomClimate roomObj
        @dataUpdated roomObj.id
        
        logger.info "WeatherManager.setRoomClimate", roomObj

    # Helper to set current conditions for outdoors.
    # Make sure data is taken out of the array and newer than current available data.
    setOutsideClimate: (data) =>
        return if not data?

        # Make sure data is taken out of the array and newer than current available data.
        # Stop here if data is not up-to-date.
        lastData = @compareGetLastData data, @data.outside
        return if not lastData?

        # Update outside data.
        @data.outside.setData lastData
        @dataUpdated "outside"
        logger.info "WeatherManager.setOutsideClimate", @data.outside

    # Helper to set current astronomy details, like sunrise and moon phase.
    setAstronomy: (data) =>
        @data.astronomy.sunrise = "#{data.value.sunrise.hour}:#{data.value.sunrise.minute}"
        @data.astronomy.sunset = "#{data.value.sunset.hour}:#{data.value.sunset.minute}"
        @data.astronomy.moon = data.value.phaseofMoon

        # Emit astronomy data and log.
        @dataUpdated "astronomy"
        logger.info "WeatherManager.setAstronomy", @data.astronomy

    # Helper to set expected conditions for outdoors.
    setCurrentConditions: (data) =>
        return if not data?

        data.value.outdoor = true

        # Update conditions and set icon.
        @data.conditions.setData data
        @data.conditions.icon = @getWeatherIcon data.value, true

        @dataUpdated "conditions"
        logger.info "WeatherManager.setCurrentConditions", @data.conditions

    # Helper to set forecast details for the next days.
    setWeatherForecast: (data, source) =>
        @data.forecast = []

        for d in data.value.forecastday
            obj = new climateModel d, source
            obj.icon = @getWeatherIcon d
            @data.forecast.push obj

        # Emit forecast dat and log.
        @dataUpdated "forecast"
        logger.info "WeatherManager.setWeatherForecast", @data.forecast

    # NETATMO
    # -------------------------------------------------------------------------

    # When Netatmo data is updated.
    onNetatmo: (key, data, filter) =>
        logger.debug "WeatherManager.onNetatmo", key, data, filter

        if key is "indoor"
            @onNetatmoIndoor data, filter
        else if key is "outdoor"
            @onNetatmoOutdoor data, filter

    # Check indoor weather conditions using Netatmo.
    onNetatmoIndoor: (data, filter) =>
        if filter["module_id"]?
            source = {"netatmo": filter["module_id"]}
        else
            source = {"netatmo": ""}

        @setRoomClimate data, source

    # Check outdoor weather conditions using Netatmo.
    onNetatmoOutdoor: (data, filter) =>
        @setOutsideClimate data, "netatmo"

    # NINJA
    # -------------------------------------------------------------------------

    # Check indoor weather conditions using Ninja Blocks.
    onNinja: (key, data, filter) =>
        logger.debug "WeatherManager.onNinja", key, data, filter

        return if key isnt "weather"

        weather = {}
        weather.temperature = data.value.temperature[0].value if data.value.temperature[0]?
        weather.humidity = data.value.humidity[0].value if data.value.humidity[0]?

        if weather.temperature? or weather.humidity?
            weather.timestamp = data.value.temperature[0].timestamp or data.value.humidity[0].timestamp

        # Update original data and set room weather.
        data.value = weather
        @setRoomClimate data, {"ninja": ""}

    # ELECTRIC IMP
    # -------------------------------------------------------------------------

    # Check indoor weather conditions using Electric Imp. We're binding to the global data event,
    # so a key is passed here as well.
    onElectricImp: (key, data, filter) =>
        logger.debug "WeatherManager.onElectricImp", key, data, filter

        @setRoomClimate data, {"electricimp": key}

    # UBI
    # -------------------------------------------------------------------------

    # Check sensor data from Ubi.
    onUbi: (key, data, filter) =>
        logger.debug "WeatherManager.onUbi", key, data, filter
        return if key isnt "sensors"

        @setRoomClimate data, {"ubi": data.value.device_id}

    # WUNDERGROUND
    # -------------------------------------------------------------------------

    # When Wunderground data is updated.
    onWunderground: (key, data, filter) =>
        logger.debug "WeatherManager.onWunderground", key, data, filter

        if key is "astronomy"
            @setAstronomy data
        else if key is "conditions"
            @setCurrentConditions data
        else if key is "astronomy"
            @setWeatherForecast data, "wunderground"

    # WEATHER MAINTENANCE
    # -------------------------------------------------------------------------

    # Turn the specified ventilator ON or OFF. Supports ninja blocks, using the
    # format {ninja: {on: "433_ID_ON", off: "433_ID_OFF"}}
    switchVentilator: (source, onOrOff, timeoutMinutes) =>
        return if not source?.ninja?

        logger.info "WeatherManager.switchVentilator", source, onOrOff, timeoutMinutes

        # Actuate correct Ninja device depending if on or off.
        if onOrOff
            events.emit "Ninja.actuate433", {id: source.ninja.on}
        else
            events.emit "Ninja.actuate433", {id: source.ninja.off}

        # Turn off automatically after timeout, if specified.
        # Convert timeout to milliseconds.
        if timeoutMinutes? and timeoutMinutes > 0 and onOrOff
            timeoutMinutes = timeoutMinutes * 60000
            lodash.delay events.emit, timeoutMinutes, "Ninja.actuate433", {id: source.ninja.off}

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
            arr = ["outside", "conditions"]

        # Iterate readings.
        for r in arr
            if @data[r].climate[prop]?
                avg += @data[r].climate[prop]
                count += 1

        # Return average reading for the specified property.
        return avg / count

    # Helper to get correct weather icon. Default is sunny / cloudy.
    getWeatherIcon: (data, nightMode) =>
        result = "sunny-cloudy"
        icon = data.icon

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
        if nightMode and result.indexOf("sunny") >= 0 and (currentHour < sunriseHour or currentHour > sunsetHour)
            result = "moon"

        return result

# Singleton implementation.
# -----------------------------------------------------------------------------
WeatherManager.getInstance = ->
    @instance = new WeatherManager() if not @instance?
    return @instance

module.exports = exports = WeatherManager.getInstance()
