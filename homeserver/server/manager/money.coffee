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
        @baseInit {recentExpenses: {}, recentIncome: {}}

    # Start the money manager and listen to data updates / events.
    start: =>
        events.on "toshl.data.recentExpenses", @onToshlRecentExpenses
        events.on "toshl.data.recentIncome", @onToshlRecentIncome

        @baseStart()

    # Stop the home manager.
    stop: =>
        @baseStop()

    # TOSHL DATA
    # -------------------------------------------------------------------------

    # When recent expenses data is returned from Toshl.
    onToshlRecentExpenses: (data) =>
        logger.debug "MoneyManager.onToshlRecentExpenses"

        # Reset current expenses.
        @data.recentExpenses.total = 0
        @data.recentExpenses.tags = {}
        @data.recentExpenses.list = []

        # Iterate and process values and tags from recent expenses.
        for e in data.value
            expenseObj = new expenseModel e, "toshl"

            @data.recentExpenses.total += expenseObj.value
            @data.recentExpenses.list.push expenseObj

            # Update recent tags values.
            for t in e.tags
                @data.recentExpenses.tags[t] = 0 if not @data.recentExpenses.tags[t]?
                @data.recentExpenses.tags[t] += expenseObj.value

        # Update recent expenses data.
        @dataUpdated "recentExpenses"

    # When recent income data is returned from Toshl.
    onToshlRecentIncome: (data) =>
        logger.debug "MoneyManager.onToshlRecentIncome"

        # Reset current expenses.
        @data.recentIncome.total = 0
        @data.recentIncome.tags = {}
        @data.recentIncome.list = []

        # Iterate and process values and tags from recent expenses.
        for i in data.value
            incomeObj = new incomeModel i, "toshl"

            @data.recentIncome.total += incomeObj.value
            @data.recentIncome.list.push incomeObj

            # Update recent tags values.
            for t in i.tags
                @data.recentIncome.tags[t] = 0 if not @data.recentIncome.tags[t]?
                @data.recentIncome.tags[t] += incomeObj.value

        # Update recent expenses data.
        @dataUpdated "recentIncome"

# Singleton implementation.
# -----------------------------------------------------------------------------
MoneyManager.getInstance = ->
    @instance = new MoneyManager() if not @instance?
    return @instance

module.exports = exports = MoneyManager.getInstance()
