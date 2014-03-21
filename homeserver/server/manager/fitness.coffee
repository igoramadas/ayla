# SERVER: FITNESS MANAGER
# -----------------------------------------------------------------------------
# Handles fitness data (sleep, weight, fat, activities etc).
class FitnessManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    title: "Fitness"

    # INIT
    # -------------------------------------------------------------------------

    # Init the fitness manager.
    init: =>
        @defaultUser = lodash.find settings.users, {isDefault: true}

        @baseInit()

    # Start the fitness manager and listen to data updates / events.
    start: =>
        events.on "withings.data.weight", @onWithingsWeight

        @baseStart()

    # Stop the fitness manager.
    stop: =>
        events.off "withings.data.weight", @onWithingsWeight

        @baseStop()

    # BODY ANALYSIS
    # -------------------------------------------------------------------------

    # When current weight is informed by Withings.
    onWithingsWeight: (data, filter) =>
        @data.weight = {value: data.weight, bmi: data.bmi}
        @dataUpdated "weight"

        logger.info "FitnessManager.onWithingsWeight", @data.weight

    # When current fat level is informed by Withings.
    onWithingsFat: (data, filter) =>
        @data.fat = {value: data.fat}
        @dataUpdated "fat"

        logger.info "FitnessManager.onWithingsFat", @data.fat

    # When current sleep data is informed by Withings.
    onWithingsSleep: (data, filter) =>
        @data.sleep = data
        @dataUpdated "sleep"

        if not data?.sleep? or data.sleep.length < 1
            msgOptions = {subject: "Missing sleep data for #{date}"}
            msgOptions.template = "fitbitMissingSleep"
            msgOptions.keywords = {date: filter.date.replace "-", "/"}

            events.emit "emailmanager.send", msgOptions

        logger.info "FitnessManager.onWithingsSleep", @data.sleep


# Singleton implementation.
# -----------------------------------------------------------------------------
FitnessManager.getInstance = ->
    @instance = new FitnessManager() if not @instance?
    return @instance

module.exports = exports = FitnessManager.getInstance()