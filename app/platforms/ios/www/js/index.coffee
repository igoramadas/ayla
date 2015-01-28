# MAIN APP CONTROLLER
window.app =
    currentView: null

    debug: =>
        console.log arguments

    init: =>
        @bindEvents()
        return true

    bindEvents: =>
        document.addEventListener "load", @onLoad, false
        document.addEventListener "deviceready", @onDeviceReady, false
        document.addEventListener "online", @onOnline, false
        document.addEventListener "offline", @onOffline, false

    onLoad: =>
        @debug "Event: load"

    onDeviceReady: =>
        @debug "Event: deviceReady"

        if not localStorage.getItem("homeserver.host")?
            @navigate "settings"
        else
            @navigate "home"

    onOnline: =>
        @debug "Event: online"

    onOffline: =>
        @debug "Event: offline"

    navigate: (id, back) =>
        @currentView.dispose() if @currentView?

        direction = if back then "right" else "left"

        window.plugins.nativepagetransitions.slide {direction: direction, href: "#" + id}, =>
            @currentView = window["#{id}View"]
            @currentView.init()
