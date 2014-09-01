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

    title: "Users"

    # INIT
    # -------------------------------------------------------------------------

    # Init the money manager.
    init: =>
        @baseInit {budget: []}

    # Start the money manager and listen to data updates / events.
    start: =>
        @baseStart()

    # Stop the home manager.
    stop: =>
        @baseStop()

    # TOSHL EXPENSES
    # -------------------------------------------------------------------------

    # When network router info is updated, check for online and offline users.
    onToshlExpenses: (data) =>
        logger.debug "MoneyManager.onToshlExpenses"

# Singleton implementation.
# -----------------------------------------------------------------------------
MoneyManager.getInstance = ->
    @instance = new MoneyManager() if not @instance?
    return @instance

module.exports = exports = MoneyManager.getInstance()
