# SERVER: LIGHT MODEL
# -----------------------------------------------------------------------------
class LightModel

    constructor: (obj, @source) ->
        id = "#{@source}-#{obj.sourceId}"

        @id = id
        @title = obj.title
        @state = obj.state
        @colour = obj.colour
        @timestamp = obj.timestamp

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = LightModel
