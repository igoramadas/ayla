# SERVER: MONEY MANAGER
# -----------------------------------------------------------------------------
# Handles user finances and budget.
class MoneyManager extends (require "./basemanager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    title: "Money"

    # INIT
    # -------------------------------------------------------------------------

    # Init the money manager.
    init: =>
        @baseInit {recentExpenses: [], recentIncome: []}

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
    @onToshlRecentExpenses: (data) =>
        logger.debug "MoneyManager.onToshlRecentExpenses"

        totalExpenses = 0

        for e in data.value
            totalExpenses += (e.amount * e.rate)

    # When recent income data is returned from Toshl.
    @onToshlRecentIncome: (data) =>
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
