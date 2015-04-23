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

        if localStorage.getItem("homeserver_url")?.toString().length > 11
            @navigate "settings"
        else
            @navigate "settings"

        # Init foundation.
        $(document).foundation()

        # Init knockout.js.
        ko.applyBindings this

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

        socketsId = id.charAt(0).toUpperCase() + id.slice(1) + "Manager.data"

        $("a.item").removeClass "active"
        $("a.item.#{id}").addClass "active"

        if @currentView?
            if @currentView.processData?
                sockets.off "#{socketsId}", @currentView.processData
            @currentView.el.hide()
            @currentView.dispose()

        @currentView = window["#{id}View"]
        @currentView.el = $ "#" + id
        @currentView.el.show()
        @currentView.init()

        # Apply KO bindings after init.
        ko.applyBindings @currentView.model, @currentView.el

        # Process data from server when received via sockets.
        if @currentView.processData?
            sockets.on "#{socketsId}", @setViewModel

    # Parse and append data from the server to the local model.
    setViewModel: (obj, dataProcessor) =>
        if _.isArray obj
            @setViewModel b for b in obj
            return

        # Run model processor, if there's one.
        @currentView.processData obj.key, obj.data if @currentView.processData?

        if @currentView.model[obj.key]?
            @currentView.model[obj.key] obj.data
        else
            @currentView.model[obj.key] = ko.observable obj.data

    # PAGE NOTIFICATIONS
    # -------------------------------------------------------------------------

    # Show a page notification.
    notify: (message) =>
        @debug "Notify", message

# BIND APP TO WINDOW
window.app = new App()
