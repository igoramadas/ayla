# SERVER: INCOME MODEL
# -----------------------------------------------------------------------------
class IncomeModel

    expresser = require "expresser"
    moment = expresser.libs.moment

    constructor: (obj, @source) ->
        id = "#{@source}-#{obj.id}"
        value = (obj.amount * obj.rate).toFixed 2

        if obj.modified?
            timestamp = moment(obj.modified.substring 20).unix()
        else
            timestamp = obj.timestamp

        @id = id
        @date = obj.date
        @amount = obj.amount
        @currency = obj.currency
        @value = value or obj.amount
        @repeat = obj.repeat.type or obj.repeat
        @timestamp = timestamp

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = IncomeModel
