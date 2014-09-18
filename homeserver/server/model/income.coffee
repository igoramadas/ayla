# SERVER: INCOME MODEL
# -----------------------------------------------------------------------------
class IncomeModel extends (require "./basemodel.coffee")

    expresser = require "expresser"
    moment = expresser.libs.moment

    # Income constructor.
    constructor: (obj, @source) ->
        @setData obj

    # Set income data.
    setData: (obj) =>
        data = obj.value or obj

        value = (data.amount / data.rate).toFixed 2
        value = parseFloat value

        if data.location?
            geolocation = [data.location.latitude, data.location.longitude]

        if data.repeat?
            repeat = data.repeat.type or data.repeat

        @date = data.date or @date
        @amount = data.amount or @amount
        @currency = data.currency or @currency
        @value = value
        @location = geolocation or @location
        @repeat = repeat or @repeat

        @afterSetData obj

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = IncomeModel
