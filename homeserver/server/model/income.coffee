# SERVER: EXPENSE MODEL
# -----------------------------------------------------------------------------
class ExpenseModel

    constructor: (obj) ->
        id = "#{obj.source}-#{obj.sourceId}"
        value = obj.amount * obj.rate

        if obj.modified?
            timestamp = new Date(obj.modified).getTime()
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
module.exports = exports = ExpenseModel
