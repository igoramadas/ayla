# SERVER: ROOM MODEL
# -----------------------------------------------------------------------------
class RoomModel

    constructor: (obj) ->
        @condition = obj.condition
        @temperature = obj.temperature
        @humidity = obj.humidity
        @pressure = obj.pressure
        @co2 = obj.co2
        @lightLevel = obj.lightLevel or obj.light
        @timestamp = obj.timestamp

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = RoomModel
