# SERVER: Activity MODEL
# -----------------------------------------------------------------------------
class ActivityModel extends (require "./basemodel.coffee")

    expresser = require "expresser"
    settings = expresser.settings

    # Activity constructor.
    constructor: (obj, @source) ->
        super obj
        @setData obj

    # Set Activity data.
    setData: (obj) =>
        data = obj.value or obj

        @title = data.title or data.name or @title
        @datetime = data.datetime or @datetime
        @type = data.type or @type
        @distance = data.distance or @distance
        @totalTime = data.totalTime or @totalTime

        @afterSetData obj

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = ActivityModel
