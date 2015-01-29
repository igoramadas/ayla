# MAIN APP CONTROLLER
# -----------------------------------------------------------------------------
class App

    currentView: null

    # Helper to debug to the console.
    # All debug calls are removed from the JS output on production builds.
    debug: =>
        console.log arguments

    # Init the app by binding main events, navigation and retrieving initial data.
    init: =>
        @bindEvents()
        @bindNavigation()

    # Bind app events.
    bindEvents: =>
        if document.URL.indexOf("http://") < 0
            document.addEventListener "load", @onLoad, false
            document.addEventListener "deviceready", @onDeviceReady, false
            document.addEventListener "online", @onOnline, false
            document.addEventListener "offline", @onOffline, false
        else
            @onDeviceReady()

    # Bind top menu and general app navigation.
    bindNavigation: =>
        $(".icon-bar a").click (e) =>
            src = $(e.currentTarget)
            @navigate src.data("view")

    # APP EVENTS
    # -------------------------------------------------------------------------

    # Called when app is loaded. First thing to happen.
    onLoad: =>
        @debug "Event: load"

    # Called after app has loaded and device is ready to be used.
    onDeviceReady: =>
        @debug "Event: deviceReady"

        if localStorage.getItem("homeserver_url")?
            @navigate "home"
        else
            @navigate "settings"

        # Init foundation.
        $(document).foundation()

        # Init pager.js and knockout.js.
        pager.extendWithPage this
        ko.applyBindings this
        pager.start()

    # Called when app is online.
    onOnline: =>
        @debug "Event: online"

    # Called when app is offline.
    onOffline: =>
        @debug "Event: offline"

    # NAVIGATION
    # -------------------------------------------------------------------------

    # Navigate to the specified page.
    navigate: (id, callback) =>
        @debug "Navigate: " + id

        $("a.item").removeClass "active"
        $("a.item.#{id}").addClass "active"

        if @currentView?
            @currentView.el.hide()
            @currentView.dispose()

        @currentView = window["#{id}View"]
        @currentView.el = $ "#" + id
        @currentView.el.show()
        @currentView.init()

    # PAGE NOTIFICATIONS
    # -------------------------------------------------------------------------

    # Show a page notification.
    notify: (message) =>
        @debug "Notify", message

# BIND APP TO WINDOW
window.app = new App()
