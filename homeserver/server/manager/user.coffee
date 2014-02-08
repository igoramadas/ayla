# SERVER: USER MANAGER
# -----------------------------------------------------------------------------
# Handles user preferences and events.
class UserManager extends (require "./baseManager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings

    hueApi = require "../api/hue.coffee"
    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    wundergroundApi = require "../api/wunderground.coffee"

    # INIT
    # -------------------------------------------------------------------------

    # Init the home manager.
    init: =>
        @baseInit {users: {}}

    # Start the home manager and listen to data updates / events.
    start: =>
        for username, userdata of settings.users
            if not @data.users[username]?
                @data.users[username] = {isOnline: false}

        events.on "network.data.router", @onNetworkRouter

        @baseStart()

    # Stop the home manager.
    stop: =>
        events.off "network.data.router", @onNetworkRouter

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
            @onUserStatus userStatus if userStatus?
            @data.users[username].isOnline = isOnline

    # Update user status (online or offline) and automatically turn off lights
    # when there's no one home for a few minutes.
    onUserStatus: (userStatus) =>
        logger.info "UserManager.onUserStatus", userStatus
        @emitData "user.status", userStatus

        # Auto control house lights?
        @switchLightsOnStatus userStatus if settings.home.autoControlLights

    # LIGHT CONTROL
    # -------------------------------------------------------------------------

    # Switch house lights based on user status.
    switchLightsOnStatus: (userStatus) =>
        logger.debug "UserManager.switchLightsOnStatus", userStatus

        # If user is online, check if lights should be turned on.
        if userStatus.isOnline
            if @timers["lightsoff"]?
                clearTimeout @timers["lightsoff"]
                delete @timers["lightsoff"]

            # Check if anyone is already home.
            anyoneOnline = false
            for u of @data.users
                anyoneOnline = true if u.isOnline

            # If first person online, get current time, sunrise and sunset hours.
            if not anyoneOnline
                currentHour = moment().hour()
                sunrise = wundergroundApi.data.astronomy?.sunrise.hour or 7
                sunset = wundergroundApi.data.astronomy?.sunset.hour or 17

                # Is it dark now? Turn lights on!
                if currentHour < sunrise or currentHour > sunset
                    logger.info "UserManager.onUserStatus", "Auto turned lights ON, #{userStatus.user} arrived."
                    hueApi.switchAllLights true

        # Otherwise proceed wich checking if everyone's offline.
        else
            everyoneOffline = true
            for u of @data.users
                everyoneOffline = false if u.isOnline

            # Everyone offline? Switch lights off after 60 seconds.
            if everyoneOffline
                logger.info "UserManager.onUserStatus", "Everyone is offline, auto turn lights OFF soon."
                @timers["lightsoff"] = lodash.delay hueApi.switchAllLights, 30000, false


# Singleton implementation.
# -----------------------------------------------------------------------------
UserManager.getInstance = ->
    @instance = new UserManager() if not @instance?
    return @instance

module.exports = exports = UserManager.getInstance()