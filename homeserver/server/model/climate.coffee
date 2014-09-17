# SERVER: CLIMATE MODEL
# -----------------------------------------------------------------------------
class ClimateModel extends (require "./basemodel.coffee")

    # Climate constructor.
    constructor: (obj, @source) ->
        @setData obj

    # Update climate data.
    setData: (obj) =>
        data = obj.value or obj

        @title = data.title or @title
        @condition = data.condition or @condition
        @temperature = data.temperature or data.temp_c or data.temp or @temperature
        @humidity = data.humidity or data.relative_humidity or @humidity
        @pressure = data.pressure or data.pressure_mb or @pressure
        
        # Property format values.
        @temperature = parseFloat(@temperature).toFixed 1 if @temperature?
        @humidity = parseFloat(@humidity.toString().replace("%", "")).toFixed 1 if @humidity?

        # Set indoor specific properties.
        if data.indoor
            @co2 = data.co2 or @co2
            @lightLevel = data.lightLevel or data.light or @lightLevel
            
        # Set outdoor specific properties.
        if data.outdoor
            @rain = data.rain or @rain
            @rain = parseFloat(@rain).toFixed 1 if @rain?
            @windSpeed = data.wind_kph or null

            # Parse wind.
            if data.wind_dir? and data.wind_kph?
                @wind = "#{data.wind_dir} #{data.wind_kph}kph"
            else if data.wind?
                @wind = data.wind

        @afterSetData obj

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = ClimateModel
