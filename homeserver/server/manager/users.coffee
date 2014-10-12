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
        @baseInit {users: [], bluetoothDevices: []}

    # Start the user manager and listen to data updates / events.
    start: =>
        @data.users = []

        for username, userdata of settings.users
            @data.users.push username

            if not @data[username]?
                user = new userModel userdata, "settings"
                user.username = username
                @data[username] = user

        events.on "Network.data", @onNetwork

        @baseStart()

    # Stop the home manager.
    stop: =>
        events.off "Network.data", @onNetwork

        @baseStop()

    # NETWORK UPDATES
    # -------------------------------------------------------------------------

    # When network data is updated.
    onNetwork: (key, data, filter) =>
        logger.debug "UsersManager.onNetwork", key, data, filter

        if key is "router"
            @onNetworkRouter data
        else if key is "bluetooth"
            @onBluetooth data
        else if key is "userPresence"
            @onUserPresence data, filter

    # When network router info is updated, check for online and offline users.
    onNetworkRouter: (data) =>
        for username, userdata of settings.users
            online = lodash.find data.wifi24g, {macaddr: userdata.computerMac}
            online = lodash.find data.wifi5g, {macaddr: userdata.computerMac} if not online?
            online = online?

            # Status updated?
            @onUserStatus {username: username, online: online} if online isnt @data[username].online
            @data[username].online = online

    # When a list of bluetooth devices are queried, update the manager's data.
    onBluetooth: (data) =>
        @data.bluetoothDevices = []

        for device in data.value
            arr = device.split "\t"
            @data.bluetoothDevices.push {name: arr[1], type: arr[2], mac: arr[0]}

        @dataUpdated "bluetoothDevices"

    # When registered user bluetooth devices are queried, check who's online (at home).
    # The filter defines the username.
    onUserPresence: (data, filter) =>
        user = data.value
        @onUserStatus {username: filter, online: user.online} if user.online isnt @data[filter].online
        @data[filter].online = user.online

    # Update user status (online or offline) and automatically turn off lights
    # when there's no one home for a few minutes. Please note that nothing will
    # happen in case the module has started less than 2 minutes ago.
    onUserStatus: (userStatus) =>
        logger.info "UsersManager.onUserStatus", userStatus

        delayedUpdate = => @dataUpdated userStatus.username
        setTimeout delayedUpdate, 500

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
                    logger.info "UsersManager.switchLightsOnStatus", "Auto turned lights ON, #{userStatus.username} arrived."
                    events.emit "hue.switchgrouplights", true

        # Otherwise proceed wich checking if everyone's offline.
        else
            everyoneOffline = true
            for u of @data
                everyoneOffline = false if u.online

            # Everyone offline? Switch lights off after a few minutes.
            if everyoneOffline
                lightsTimeout = settings.home.lightsTimeout * 60000
                logger.info "UsersManager.switchLightsOnStatus", "Everyone is offline, auto turn lights OFF in #{lightsTimeout} min."
                @timers["lightsoff"] = lodash.delay events.emit, lightsTimeout, "hue.switchgrouplights", false

# Singleton implementation.
# -----------------------------------------------------------------------------
UsersManager.getInstance = ->
    @instance = new UsersManager() if not @instance?
    return @instance

module.exports = exports = UsersManager.getInstance()
