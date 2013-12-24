# FITBIT
# -----------------------------------------------------------------------------
class Fitbit

    expresser = require "expresser"
    logger = expresser.logger

    # AUTH
    # -------------------------------------------------------------------------

    auth: =>

    # SLEEP
    # -------------------------------------------------------------------------

    getSleepData: (since) =>

    # ACTIVITIES
    # -------------------------------------------------------------------------

    # Post an activity to Fitbit.
    postActivity: (activity) =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Fitbit.getInstance = ->
    @instance = new Fitbit() if not @instance?
    return @instance

module.exports = exports = Fitbit.getInstance()