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
        @baseInit {recentExpenses: {}, recentIncomes: {}}

    # Start the money manager and listen to data updates / events.
    start: =>
        events.on "toshl.data.recentExpenses", @onToshlRecentExpenses
        events.on "toshl.data.recentIncomes", @onToshlRecentIncomes

        @baseStart()

    # Stop the home manager.
    stop: =>
        @baseStop()

    # TOSHL DATA
    # -------------------------------------------------------------------------

    # When recent expenses data is returned from Toshl.
    onToshlRecentExpenses: (data) =>
        logger.debug "MoneyManager.onToshlRecentExpenses"

        # Reset current expenses data.
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
    onToshlRecentIncomes: (data) =>
        logger.debug "MoneyManager.onToshlRecentIncomes"

        # Reset current income data.
        @data.recentIncomes.total = 0
        @data.recentIncomes.tags = {}
        @data.recentIncomes.list = []

        # Iterate and process values and tags from recent income.
        for i in data.value
            incomeObj = new incomeModel i, "toshl"

            @data.recentIncomes.total += incomeObj.value
            @data.recentIncomes.list.push incomeObj

            # Update recent tags values.
            for t in i.tags
                @data.recentIncomes.tags[t] = 0 if not @data.recentIncomes.tags[t]?
                @data.recentIncomes.tags[t] += incomeObj.value

        # Update recent income data.
        @dataUpdated "recentIncomes"

# Singleton implementation.
# -----------------------------------------------------------------------------
MoneyManager.getInstance = ->
    @instance = new MoneyManager() if not @instance?
    return @instance

module.exports = exports = MoneyManager.getInstance()
