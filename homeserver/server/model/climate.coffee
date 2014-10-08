# SERVER: CLIMATE MODEL
# -----------------------------------------------------------------------------
class ClimateModel extends (require "./basemodel.coffee")

    expresser = require "expresser"
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    # Climate constructor.
    constructor: (obj, @source) ->
        @setData obj

    # Update climate data.
    setData: (obj) =>
        data = obj.value or obj

        @date = @getValue [data.date, @date]
        @title = @getValue [data.title, @title]
        @condition = @getValue [data.condition, @condition]
        @temperature = @getValue [data.temperature, data.temp_c, data.temp, @temperature]
        @temperatureHigh = @getValue [data.temperatureHigh, data.high?.celsius, @temperatureHigh]
        @temperatureLow = @getValue [data.temperatureLow, data.low?.celsius, @temperatureLow]
        @humidity = @getValue [data.humidity, data.relative_humidity, data.avehumidity, @humidity]
        @pressure = @getValue [data.pressure, data.pressure_mb, @pressure]

        # Set the friendly date string.
        if @date?
            if lodash.isString @date
                currentDate = @date
            else
                if @date.epoch > 0
                    currentDate = moment.unix(@date.epoch).format "L"
                else
                    currentDate = moment(@date).format "L"

            if currentDate is moment().format "L"
                @dateString = "Today"
            else if currentDate is moment().add(1, "d").format "L"
                @dateString = "Tomorrow"
            else
                @dateString = currentDate
        
        # Property format temperature.
        if @temperature?
            @temperature = parseFloat(@temperature).toFixed 1
            @temperature = parseFloat @temperature

        # Properly format humidity.
        if @humidity?
            @humidity = parseFloat(@humidity.toString().replace("%", "")).toFixed 0
            @humidity = parseFloat @humidity
            @humidity = 100 if @humidity > 100
            @humidity = 0 if @humidity < 0

        # Set indoor specific properties.
        if data.indoor
            @co2 = @getValue [data.co2, @co2]
            @lightLevel = @getValue [data.lightLevel, data.light, @lightLevel]
        else
            @precp = @getValue [data.precp, data.rain, @precp]
            @precpChance = @getValue [data.precpChance, data.pop, @precpChance]
            @windDirection = @getValue [data.windDirection, data.avewind?.dir, data.wind_dir, @windDirection]
            @windSpeed = @getValue [data.windSpeed, data.avewind?.kph, data.wind_kph, @windSpeed]
            @windSpeedMax = @getValue [data.windSpeedMax, data.maxwind?.kph, @windSpeedMax]

            # Guess precipitation chance.
            if not @precpChance? and data.precip_1hr_metric?
                if data.precip_1hr_metric > 1
                    @precpChance = 100
                else if data.precip_1hr_metric > 0
                    @precpChance = 50
                else
                    @precpChance = 0

            # Properly set precipitation value.
            if @precp?
                @precp = parseFloat(@precp).toFixed 1
                @precp = parseFloat @precp

        @afterSetData obj

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = ClimateModel
