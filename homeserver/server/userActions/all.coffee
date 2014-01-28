# USER ACTIONS: ALL USERS
# -----------------------------------------------------------------------------
class UserActions_All

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger

    # CONSTRUCTOR
    # -------------------------------------------------------------------------

    # Constructs a new light model.
    constructor: ->
        events.on "network.user.status", @onNetworkUserStatus

    # EVENTS
    # -------------------------------------------------------------------------

    # Triggered when user
    onNetworkUserStatus: (user) =>
        console.warn user


# Exports (not singleton!)
# -----------------------------------------------------------------------------
module.exports = exports = UserActions_All