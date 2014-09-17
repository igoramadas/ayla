# SERVER: ROOM MODEL
# -----------------------------------------------------------------------------
class RoomModel extends (require "./basemodel.coffee")

    expresser = require "expresser"
    climateModel = require "../model/climate.coffee"
    settings = expresser.settings

    # Room constructor.
    constructor: (obj, @source) ->
        @setData obj

    # Set room data and check climate conditions straight away.
    setData: (obj) =>
        data = obj.value or obj

        @title = data.title or @title
        @climateSource = data.climateSource or @climateSource

        if @climateModel?
            @climate.setData data
        else
            @climate = new climateModel data, @source

        @checkClimate()
        @afterSetData obj

    # Helper to verify room climate and set its condition.
    checkClimate: =>
        return if not @climate?

        conditions = []

        # Check temperatures.
        if @climate.temperature?
            if @climate.temperature > settings.home.idealConditions.temperature[3]
                conditions.push "Too warm"
            else if @climate.temperature > settings.home.idealConditions.temperature[2]
                conditions.push "A bit warm"
            else if @climate.temperature < settings.home.idealConditions.temperature[1]
                conditions.push "A bit cold"
            else if @climate.temperature < settings.home.idealConditions.temperature[0]
                conditions.push "Too cold"

        # Check humidity.
        if @climate.humidity?
            if @climate.humidity > settings.home.idealConditions.humidity[3]
                conditions.push "Too humid"
            else if @climate.humidity > settings.home.idealConditions.humidity[2]
                conditions.push "A bit humid"
            else if @climate.humidity < settings.home.idealConditions.humidity[1]
                conditions.push "A bit dry"
            else if @climate.humidity < settings.home.idealConditions.humidity[0]
                conditions.push "Too dry"

        # Check CO2.
        if @climate.co2?
            if @climate.co2 > settings.home.idealConditions.co2[3]
                conditions.push "CO2 too high"
            else if @climate.co2 > settings.home.idealConditions.co2[2]
                conditions.push "CO2 high"

        # If no conditions were added, set condition as good.
        if conditions.length < 1
            @climate.condition = "Good"
        else
            @climate.condition = conditions.join ", "

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = RoomModel
