# SERVER: MONEY MANAGER
# -----------------------------------------------------------------------------
# Handles user finances and budget.
class MoneyManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    expenseModel = require "../model/expense.coffee"
    events = expresser.events
    incomeModel = require "../model/income.coffee"
    lodash = expresser.libs.lodash
    logger = expresser.logger
    mailer = expresser.mailer
    moment = expresser.libs.moment
    settings = expresser.settings

    title: "Money"

    # INIT
    # -------------------------------------------------------------------------

    # Init the money manager.
    init: =>
        @baseInit {recentExpenses: {}, recentIncomes: {}, months: []}

    # Start the money manager and listen to data updates / events.
    start: =>
        events.on "Toshl.data", @onToshl

        @baseStart()

    # Stop the home manager.
    stop: =>
        events.off "Toshl.data", @onToshl

        @baseStop()

    # TOSHL DATA
    # -------------------------------------------------------------------------

    # When Toshl data is updated.
    onToshl: (key, data, filter) =>
        logger.debug "MoneyManager.onToshl", key, data, filter

        if key is "months"
            @onToshlMonths data
        else if key is "recentExpenses"
            @onToshlRecentExpenses data
        else if key is "recentIncomes"
            @onToshlRecentIncomes data

    # When months data is returned from Toshl.
    onToshlMonths: (data) =>
        @data.months = []

        # Iterate months.
        for m in data.value
            month = {expenses: m.expenses, incomes: m.incomes}
            month.date = moment(new Date(m.from))
            month.shortDate = month.date.format "MMM YY"

            @data.months.push month

        # Update months data.
        @dataUpdated "months"

    # When recent expenses data is returned from Toshl.
    onToshlRecentExpenses: (data) =>
        logger.debug "MoneyManager.onToshlRecentExpenses"

        @processRecentToshlData @data.recentExpenses, data, expenseModel, "Expenses"

    # When recent income data is returned from Toshl.
    onToshlRecentIncomes: (data) =>
        logger.debug "MoneyManager.onToshlRecentIncomes"

        @processRecentToshlData @data.recentIncomes, data, incomeModel, "Incomes"

    # Helper to process recent expenses and incomes from Toshl.
    processRecentToshlData: (target, data, model, key) =>
        target.total = 0
        target.tags = []
        target.list = []

        # Object to hold tag values.
        tags = {}

        # Iterate and process values and tags.
        for e in data.value
            obj = new model e, "toshl"

            target.total += obj.value
            target.list.push obj

            # Update recent tags values.
            for t in e.tags
                tags[t] = {tag: t, total: 0, last3: 0, last10: 0} if not tags[t]?
                tags[t].total += obj.value

                if obj.date > moment().subtract(3, "d").format settings.toshl.dateFormat
                    tags[t].last3 += obj.value

                if obj.date > moment().subtract(10, "d").format settings.toshl.dateFormat
                    tags[t].last10 += obj.value

        # Add tags to target list.
        target.tags.push tagdata for tag, tagdata of tags
        target.tags = lodash.sortBy target.tags, "tag"

        # Update recent data.
        @dataUpdated "recent#{key}"

# Singleton implementation.
# -----------------------------------------------------------------------------
MoneyManager.getInstance = ->
    @instance = new MoneyManager() if not @instance?
    return @instance

module.exports = exports = MoneyManager.getInstance()
