# SERVER: MONEY MANAGER
# -----------------------------------------------------------------------------
# Handles user finances and budget.
class MoneyManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    expensemodel = require "../model/expense.coffee"
    events = expresser.events
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

        totalExpenses = 0
        recentTags = {}

        # Iterate and process values and tags from recent expenses.
        for e in data.value
            expenseObj = new expensemodel e
            totalExpenses += expenseObj.value

            @data.recentExpenses.list.push expenseObj

            # Update recent tags values.
            for t in e.tags
                recentTags[t] = 0 if not recentTags[t]?
                recentTags[t] += expenseObj.value

        # Update recent expenses data.
        @data.recentExpenses.total = totalExpenses
        @data.recentExpenses.tags = recentTags

        @dataUpdated "recentExpenses"

    # When recent income data is returned from Toshl.
    onToshlRecentIncome: (data) =>
        logger.debug "MoneyManager.onToshlRecentIncome"

        totalIncome = 0

        for i in data.value
            totalIncome += (e.amount * e.rate)

# Singleton implementation.
# -----------------------------------------------------------------------------
MoneyManager.getInstance = ->
    @instance = new MoneyManager() if not @instance?
    return @instance

module.exports = exports = MoneyManager.getInstance()
