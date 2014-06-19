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
        events.on "withings.data.bodymeasures", @onWithingsBody

        @baseStart()

    # Stop the fitness manager.
    stop: =>
        events.off "withings.data.bodymeasures", @onWithingsBody

        @baseStop()

    # BODY ANALYSIS
    # -------------------------------------------------------------------------

    # When current body data is informed by Withings.
    onWithingsBody: (data, filter) =>
        @data.bodymeasures = {timestamp: 0} if not @data.bodymeasures?

        sorted = lodash.sortBy data.body.measuregrps, "date"
        newest = sorted.pop()

        # Check if data has more recent readings for body measures.
        if newest.date > @data.bodymeasures.timestamp
            weight = lodash.filter newest.measures, {type: 1}
            fat = lodash.filter newest.measures, {type: 6}
            @data.bodymeasures.weight = weight[0].value / 1000 if weight.length > 0
            @data.bodymeasures.fat = fat[0].value / 1000 if fat.length > 0
            @dataUpdated "bodymeasures"

        logger.info "FitnessManager.onWithingsBody", @data.bodymeasures


# Singleton implementation.
# -----------------------------------------------------------------------------
FitnessManager.getInstance = ->
    @instance = new FitnessManager() if not @instance?
    return @instance

module.exports = exports = FitnessManager.getInstance()
