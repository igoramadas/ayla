# SERVER: FITNESS MANAGER
# -----------------------------------------------------------------------------
# Handles fitness data (sleep, weight, fat, activities etc).
class FitnessManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings

    title: "Fitness"

    # INIT
    # -------------------------------------------------------------------------

    # Init the fitness manager.
    init: =>
        @defaultUser = lodash.find settings.users, {isDefault: true}

        @baseInit()

    # Start the fitness manager and listen to data updates / events.
    start: =>
        events.on "Withings.data", @onWithings

        @baseStart()

    # Stop the fitness manager.
    stop: =>
        events.off "Withings.data", @onWithings

        @baseStop()

    # BODY ANALYSIS
    # -------------------------------------------------------------------------

    # When current body data is informed by Withings.
    onWithings: (key, data, filter) =>
        return if key isnt "bodyMeasures"
        @data.recentBodyMeasures = {timestamp: 0} if not @data.recentBodyMeasures?

        sorted = lodash.sortBy data.value.body.measuregrps, "date"
        newest = sorted.pop()

        # Check if data has more recent readings for body measures.
        if newest.date > @data.recentBodyMeasures.timestamp
            weight = lodash.filter newest.measures, {type: 1}
            fat = lodash.filter newest.measures, {type: 6}
            @data.recentBodyMeasures.weight = weight[0].value / 1000 if weight.length > 0
            @data.recentBodyMeasures.fat = fat[0].value / 1000 if fat.length > 0
            @dataUpdated "recentBodyMeasures"

        logger.info "FitnessManager.onWithingsBody", @data.recentBodyMeasures

# Singleton implementation.
# -----------------------------------------------------------------------------
FitnessManager.getInstance = ->
    @instance = new FitnessManager() if not @instance?
    return @instance

module.exports = exports = FitnessManager.getInstance()
