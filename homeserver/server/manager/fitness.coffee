# SERVER: HOME MANAGER
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

    # INIT
    # -------------------------------------------------------------------------

    # Init the fitness manager.
    init: =>
        @defaultUser = lodash.find settings.users, {isDefault: true}

        @baseInit()

    # Start the fitness manager and listen to data updates / events.
    start: =>
        events.on "fitbit.data.weight", @onFitbitWeight
        events.on "fitbit.data.fat", @onFitbitFat
        events.on "fitbit.data.sleep", @onFitbitSleep

        @baseStart()

    # Stop the fitness manager.
    stop: =>
        events.off "fitbit.data.weight", @onFitbitWeight
        events.off "fitbit.data.fat", @onFitbitFat
        events.off "fitbit.data.sleep", @onFitbitSleep

        @baseStop()

    # BODY ANALYSIS
    # -------------------------------------------------------------------------

    # When current weight is informed by Fitbit.
    onFitbitWeight: (data) =>
        @data.weight = {value: data.weight, bmi: data.bmi}
        @dataUpdated "weight"

        logger.info "FitnessManager.onFitbitWeight", @data.weight

    # When current fat level is informed by Fitbit.
    onFitbitFat: (data) =>
        @data.fat = {value: data.fat}
        @dataUpdated "fat"

        logger.info "FitnessManager.onFitbitFat", @data.fat

    # When current sleep data is informed by Fitbit.
    onFitbitSleep: (data) =>
        @data.sleep = data
        @dataUpdated "sleep"

        logger.info "FitnessManager.onFitbitSleep", @data.sleep


# Singleton implementation.
# -----------------------------------------------------------------------------
FitnessManager.getInstance = ->
    @instance = new FitnessManager() if not @instance?
    return @instance

module.exports = exports = FitnessManager.getInstance()