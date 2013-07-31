# FITBIT
# -----------------------------------------------------------------------------

class Fitbit

    # Required modules.
    expresser = require "expresser"


    # AUTH
    # -----------------------------------------------------------------------------

    auth:


    # ACTIVITIES
    # -----------------------------------------------------------------------------

    # Post an activity to Fitbit.
    postActivity: (activity) =>



# Singleton implementation.
# -----------------------------------------------------------------------------
Fitbit.getInstance = ->
    @instance = new Fitbit() if not @instance?
    return @instance

module.exports = exports = Fitbit.getInstance()