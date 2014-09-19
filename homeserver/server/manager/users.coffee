# SERVER: USERS MANAGER
# -----------------------------------------------------------------------------
# Handles user presence and personal actions.
class UsersManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    datastore = expresser.datastore
    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    mailer = expresser.mailer
    moment = expresser.libs.moment
    settings = expresser.settings
    userModel = require "../model/user.coffee"

    title: "Users"

    # INIT
    # -------------------------------------------------------------------------

    # Init the user manager.
    init: =>
        @baseInit {users: []}

    # Start the user manager and listen to data updates / events.
    start: =>
        @data.users = []

        for username, userdata of settings.users
            @data.users.push username

            if not @data[username]?
                user = new userModel userdata, "settings"
                user.username = username
                @data[username] = user

        events.on "network.data.router", @onNetworkRouter
        events.on "network.data.bluetoothUsers", @onBluetoothUsers

        @baseStart()

    # Stop the home manager.
    stop: =>
        events.off "network.data.router", @onNetworkRouter
        events.off "network.data.bluetoothUsers", @onBluetoothUsers

        @baseStop()

    # USER STATUS
    # -------------------------------------------------------------------------

    # When network router info is updated, check for online and offline users.
    onNetworkRouter: (data) =>
        logger.debug "UsersManager.onNetworkRouter"

        for username, userdata of settings.users
            online = lodash.find data.wifi24g, {macaddr: userdata.computerMac}
            online = lodash.find data.wifi5g, {macaddr: userdata.computerMac} if not online?
            online = online?

            # Status updated?
            @onUserStatus {user: username, online: online} if online isnt @data[d.user].online
            @data[username].online = online

    # When user bluetooth devices are queried, check who's online (at home).
    onBluetoothUsers: (data) =>
        logger.debug "UsersManager.onBluetoothUsers"

        for d in data.value
            @onUserStatus {user: d.user, online: d.online} if d.online isnt @data[d.user].online
            @data[d.user].online = d.online

    # Update user status (online or offline) and automatically turn off lights
    # when there's no one home for a few minutes. Please note that nothing will
    # happen in case the module has started less than 2 minutes ago.
    onUserStatus: (userStatus) =>
        if moment().subtract(2, "m").unix() < @initTimestamp
            logger.debug "UsersManager.onUserStatus", userStatus, "Do nothing! Module has just started."
            return

        logger.info "UsersManager.onUserStatus", userStatus

        # Auto control house lights?
        @switchLightsOnStatus userStatus if settings.home.autoControlLights

    # LIGHT CONTROL
    # -------------------------------------------------------------------------

    # Switch house lights based on user status.
    switchLightsOnStatus: (userStatus) =>
        logger.debug "UsersManager.switchLightsOnStatus", userStatus

        # If user is online, check if lights should be turned on.
        if userStatus.online
            if @timers["lightsoff"]?
                clearTimeout @timers["lightsoff"]
                delete @timers["lightsoff"]

            # Check if anyone is already home.
            anyoneOnline = false
            for u of @data
                anyoneOnline = true if u.online

            # If first person online, get current time, sunrise and sunset hours.
            if not anyoneOnline
                currentHour = moment().hour()
                sunrise = datastore.WeatherManager.astronomy?.sunrise.hour or 7
                sunset = datastore.WeatherManager.astronomy?.sunset.hour or 17

                # Is it dark now? Turn lights on!
                if currentHour < sunrise or currentHour > sunset
                    logger.info "UsersManager.onUserStatus", "Auto turned lights ON, #{userStatus.user} arrived."
                    events.emit "hue.switchgrouplights", true

        # Otherwise proceed wich checking if everyone's offline.
        else
            everyoneOffline = true
            for u of @data
                everyoneOffline = false if u.online

            # Everyone offline? Switch lights off after a few minutes.
            if everyoneOffline
                lightsTimeout = settings.home.lightsTimeout * 60000
                logger.info "UsersManager.onUserStatus", "Everyone is offline, auto turn lights OFF in #{lightsTimeout} min."
                @timers["lightsoff"] = lodash.delay events.emit, lightsTimeout, "hue.switchgrouplights", false

# Singleton implementation.
# -----------------------------------------------------------------------------
UsersManager.getInstance = ->
    @instance = new UsersManager() if not @instance?
    return @instance

module.exports = exports = UsersManager.getInstance()
