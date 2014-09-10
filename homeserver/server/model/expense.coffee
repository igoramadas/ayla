# SERVER: INCOME MODEL
# -----------------------------------------------------------------------------
class IncomeModel

    constructor: (obj) ->
        id = "#{obj.source}-#{obj.id}"
        value = obj.amount * obj.rate
        modified = new Date(obj.modified).getTime()

        if obj.modified?
            timestamp = new Date(obj.modified).getTime()
        else
            timestamp = obj.timestamp

        @id = id
        @date = obj.date
        @amount = obj.amount
        @currency = obj.currency
        @value = value or obj.amount
        @location = [obj.location.latitude, obj.location.longitude]
        @repeat = obj.repeat.type or obj.repeat
        @timestamp = timestamp

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = IncomeModel
