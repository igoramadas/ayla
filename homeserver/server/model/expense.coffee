# SERVER: EXPENSE MODEL
# -----------------------------------------------------------------------------
class ExpenseModel

    expresser = require "expresser"
    moment = expresser.libs.moment

    constructor: (obj, @source) ->
        id = "#{@source}-#{obj.id}"
        value = (obj.amount * obj.rate).toFixed 2
        value = parseFloat value

        if obj.modified?
            timestamp = moment(new Date(obj.modified.substring 20)).unix()
        else
            timestamp = obj.timestamp

        if obj.location?
            geolocation = [obj.location.latitude, obj.location.longitude]

        if obj.repeat?
            repeat = obj.repeat.type or obj.repeat

        @id = id
        @date = obj.date
        @amount = obj.amount
        @currency = obj.currency
        @value = value or obj.amount
        @location = geolocation
        @repeat = repeat
        @timestamp = timestamp

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = ExpenseModel
