# SERVER: FITNESS MODEL
# -----------------------------------------------------------------------------
class FitnessModel extends (require "./basemodel.coffee")

    expresser = require "expresser"
    settings = expresser.settings

    # Fitness constructor.
    constructor: (obj, @source) ->
        @setData obj

    # Set Fitness data.
    setData: (obj) =>
        data = obj.value or obj

        @name = data.name or @name
        @height = data.height or @height
        @weight = data.weight or @weight
        @fat = data.fat or @fat

        @afterSetData obj

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = FitnessModel
