# SERVER: HOME MANAGER
# -----------------------------------------------------------------------------
# Handles home weather and climate conditions.
class WeatherManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    appData = require "../appdata.coffee"
    climateModel = require "../model/climate.coffee"
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    spaceModel = require "../model/space.coffee"
    settings = expresser.settings
    sockets = expresser.sockets

    title: "Weather"
    icon: "fa-cloud"

    # INIT
    # -------------------------------------------------------------------------

    # Init the weather manager with the default values.
    init: =>
        astronomy = {sunrise: "7:00", sunset: "18:00"}
        outside = new climateModel {title: "Outside"}
        current = new climateModel {title: "Current forecast"}

        @baseInit {forecastDays: [], forecastCurrent: current, astronomy: astronomy, outside: outside, spaces: appData.spaces}

    # Start the weather manager and listen to data updates / events.
    # Indoor weather data depends on spaces being set on the settings.
    start: =>
        if not appData.spaces?
            logger.warn "WeatherManager.start", "No spaces were defined on the settings. Indoor weather won't be monitored."
        else
            for space in appData.spaces
                @data[space.id] = new spaceModel(space) if not @data[space.id]?

        events.on "Netatmo.data", @onNetatmo
        events.on "Wunderground.data", @onWunderground

        @baseStart()

    # Stop the weather manager.
    stop: =>
        events.off "Netatmo.data", @onNetatmo
        events.off "Wunderground.data", @onWunderground

        @baseStop()

    # WEATHER AND CLIMATE
    # -------------------------------------------------------------------------

    # Helper to verify if space climate is in good condition. Do necessary actions
    # and notify if it's not.
    checkSpaceClimate: (space) =>
        return if not space.climate?

        notifyOptions = {}
        condition = space.climate.condition.toLowerCase()

        # Check temperature.
        if condition.indexOf("too warm") >= 0
            notifyOptions.critical = true
            @switchVentilator space.ventilatorSource, true, settings.home.ventilatorTimeout
        else if condition.indexOf("too cold") >= 0
            notifyOptions.critical = true

        # Check humidity.
        if condition.indexOf("too humid") >= 0
            notifyOptions.critical = true
            @switchVentilator space.ventilatorSource, true, settings.home.ventilatorTimeout
        else if condition.indexOf("too dry") >= 0
            notifyOptions.critical = true

        # Check CO2.
        if condition.indexOf("co2 too high") >= 0
            notifyOptions.critical = true

        # Alert about bad space conditions.
        if condition isnt "good"
            notifyOptions.subject = "#{space.title}: #{space.climate.condition}"
            notifyOptions.message =  "Conditions: temperature #{space.climate.temperature}, humidity #{space.climate.humidity}, CO2 #{space.climate.co2}."

            @notify notifyOptions

    # Helper to set current conditions for the specified space.
    setSpaceClimate: (data, source) =>
        return if not data?

        # Find space linked to the specified weather source.
        try
            spaceObj = lodash.find @data, {climateSource: source}
        catch ex
            logger.error "WeatherManager.setSpaceClimate", source, data, ex.message
        return if not spaceObj?

        # No space found? Abort here.
        if not spaceObj?.id?
            logger.warn "WeatherManager.setSpaceClimate", source, "Space not properly set, check the 'home.json' spaces and make sure they all have an ID set."
            return

        # Make sure data is taken out of the array and newer than current available data.
        # Stop here if data is not up-to-date.
        lastData = @compareGetLastData data, spaceObj
        return if not lastData?

        # Set space data and check its climate.
        @data[spaceObj.id].setData lastData
        @checkSpaceClimate spaceObj
        @dataUpdated spaceObj.id

        logger.info "WeatherManager.setSpaceClimate", spaceObj

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
    setForecastCurrent: (data) =>
        return if not data?

        data.value.outdoor = true

        # Update conditions and set icon.
        @data.forecastCurrent.setData data
        @data.forecastCurrent.icon = @getWeatherIcon data.value, true

        @dataUpdated "forecastCurrent"
        logger.info "WeatherManager.setForecastCurrent", @data.forecastCurrent

    # Helper to set forecast details for the next days.
    setForecastDays: (data, source) =>
        @data.forecastDays = []

        for d in data.value.forecastday
            d.outdoor = true
            obj = new climateModel d, source
            obj.icon = @getWeatherIcon d
            @data.forecastDays.push obj

        # Emit forecast dat and log.
        @dataUpdated "forecastDays"
        logger.info "WeatherManager.setForecastDays", @data.forecastDays

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

        @setSpaceClimate data, source

    # Check outdoor weather conditions using Netatmo.
    onNetatmoOutdoor: (data, filter) =>
        @setOutsideClimate data, "netatmo"

    # WUNDERGROUND
    # -------------------------------------------------------------------------

    # When Wunderground data is updated.
    onWunderground: (key, data, filter) =>
        logger.debug "WeatherManager.onWunderground", key, data, filter

        if key is "astronomy"
            @setAstronomy data
        else if key is "conditions"
            @setForecastCurrent data
        else if key is "forecast"
            @setForecastDays data, "wunderground"

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

        # Set properties to be read (indoor spaces or outdoor / conditions).
        if where is "indoor"
            arr = lodash.pluck appData.home.spaces, "id"
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
    getWeatherIcon: (data, considerTime) =>
        result = "day-cloudy"
        icon = data.icon

        currentHour = moment().hour()
        sunriseHour = parseInt @data.astronomy.sunrise?.split(":")[0]
        sunsetHour = parseInt @data.astronomy.sunset?.split(":")[0]

        icon = icon.replace(".gif", "").replace("nt_", "")

        if "fog,hazy".indexOf(icon) >= 0
            result = "day-fog"
        if "cloudy,mostlycloudy".indexOf(icon) >= 0
            result = "cloudy"
        else if "chancerain,chancesleet".indexOf(icon) >= 0
            result = "day-sprinkle"
        else if "rain,sleet".indexOf(icon) >= 0
            result = "rain"
        else if "chanceflurries,flurries,chancesnow,snow".indexOf(icon) >= 0
            result = "snow"
        else if "clear,sunny".indexOf(icon) >= 0
            result = "day-sunny"
        else if "chancestorms,tstorms".indexOf(icon) >= 0
            result = "thunderstorm"

        # Force moon icon when clear skies at night.
        if considerTime and result.indexOf("sunny") >= 0 and (currentHour < sunriseHour or currentHour > sunsetHour)
            result = "moon-old"

        return result

# Singleton implementation.
# -----------------------------------------------------------------------------
WeatherManager.getInstance = ->
    @instance = new WeatherManager() if not @instance?
    return @instance

module.exports = exports = WeatherManager.getInstance()
