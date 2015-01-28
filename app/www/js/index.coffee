# MAIN APP CONTROLLER
class App
    currentView: null

    debug: =>
        console.log arguments

    init: =>
        @bindEvents()
        @bindNavigation()
        return true

    bindEvents: =>
        document.addEventListener "load", @onLoad, false
        document.addEventListener "deviceready", @onDeviceReady, false
        document.addEventListener "online", @onOnline, false
        document.addEventListener "offline", @onOffline, false

    bindNavigation: =>
        $(".icon-bar a").click (e) =>
            src = $(e.target)
            @navigate src.data("view")

    onLoad: =>
        @debug "Event: load"

    onDeviceReady: =>
        @debug "Event: deviceReady"

        if not localStorage.getItem("homeserver_url")?
            @navigate "settings"
        else
            @navigate "home"

    onOnline: =>
        @debug "Event: online"

    onOffline: =>
        @debug "Event: offline"

    navigate: (id, callback) =>
        if @currentView?
            @currentView.dispose()
            @currentView.el.hide()

        @currentView = window["#{id}View"]
        @currentView.el.show()
        @currentView.init()

window.app = new App()
