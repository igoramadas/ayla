# MAIN APP CONTROLLER
# --------------------------------------------------------------------------
class App

    currentView: null

    debug: =>
        console.log arguments

    init: =>
        @bindEvents()
        @bindNavigation()

    bindEvents: =>
        if document.URL.indexOf("http://") < 0
            document.addEventListener "load", @onLoad, false
            document.addEventListener "deviceready", @onDeviceReady, false
            document.addEventListener "online", @onOnline, false
            document.addEventListener "offline", @onOffline, false
        else
            @onDeviceReady()

    bindNavigation: =>
        $(".icon-bar a").click (e) =>
            src = $(e.currentTarget)
            @navigate src.data("view")

    onLoad: =>
        @debug "Event: load"

    onDeviceReady: =>
        @debug "Event: deviceReady"

        if localStorage.getItem("homeserver_url")?
            @navigate "home"
        else
            @navigate "settings"

    onOnline: =>
        @debug "Event: online"

    onOffline: =>
        @debug "Event: offline"

    navigate: (id, callback) =>
        @debug "Navigate: " + id

        if @currentView?
            @currentView.el.hide()
            @currentView.dispose()

        @currentView = window["#{id}View"]
        @currentView.el = $ "#" + id
        @currentView.el.show()
        @currentView.init()

# BIND APP TO WINDOW
window.app = new App()
