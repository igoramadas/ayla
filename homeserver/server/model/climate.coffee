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

        @date = data.date
        @title = data.title
        @condition = data.condition
        @temperature = data.temperature or data.temp_c or data.temp
        @temperatureHigh = data.temperatureHigh or data.high?.celsius
        @temperatureLow = data.temperatureLow or data.low?.celsius
        @humidity = data.humidity or data.relative_humidity or data.avehumidity
        @pressure = data.pressure or data.pressure_mb

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
            @humidity = parseFloat(@humidity.toString().replace("%", "")).toFixed 1
            @humidity = parseFloat @humidity
            @humidity = 100 if @humidity > 100

        # Set indoor specific properties.
        if data.indoor
            @co2 = data.co2 or @co2
            @lightLevel = data.lightLevel or data.light
        else
            @precp = data.precp or data.rain
            @precpChance = data.precpChance or data.pop
            @windDirection = data.windDirection or data.avewind?.dir or data.wind_dir
            @windSpeed = data.windSpeed or data.avewind?.kph or data.wind_kph or 0
            @windSpeedMax = data.windSpeedMax or data.maxwind?.kph

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
