# SERVER: USER MANAGER
# -----------------------------------------------------------------------------
# Handles user preferences and events.
class UserManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings

    # INIT
    # -------------------------------------------------------------------------

    # Init the home manager.
    init: =>
        @data.users = {}
        @data.users[username] = {isOnline: false} for username, userdata of settings.users
        @baseInit()

    # Start the home manager and listen to data updates / events.
    start: =>
        events.on "network.data.router", @onNetworkRouter

        @baseStart()

    # Stop the home manager.
    stop: =>
        @baseStop()

    # USER STATUS
    # -------------------------------------------------------------------------

    # When network router info is updated, check for online and offline users.
    onNetworkRouter: (data) =>
        logger.debug "UserManager.onNetworkRouter"

        for username, userdata of settings.users
            isOnline = lodash.find data.wifi24g, {macaddr: userdata.mac}
            isOnline = lodash.find data.wifi5g, {macaddr: userdata.mac} if not isOnline?
            isOnline = isOnline?
            userStatus = null

            # User status just changed? Emit event to notify other modules.
            if isOnline and not @users[username].isOnline
                userStatus = {user: username, isOnline: true}
            else if not isOnline and @users[username].isOnline
                userStatus = {user: username, isOnline: false}

            # Status updated?
            if userStatus?
                @onUserStatus userStatus

            @data.users[username].isOnline = isOnline

    # Update user status (online or offline) and automatically turn off lights
    # when there's no one home for a few minutes.
    onUserStatus: (data) =>
        logger.info "UserManager.onUserStatus", data
        events.emit "usermanager.user.status",data


# Singleton implementation.
# -----------------------------------------------------------------------------
UserManager.getInstance = ->
    @instance = new UserManager() if not @instance?
    return @instance

module.exports = exports = UserManager.getInstance()