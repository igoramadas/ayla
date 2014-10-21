# BASE VIEW
# --------------------------------------------------------------------------
class BaseView

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the view and set elements.
    init: (callback) =>
        @viewId = @__proto__.constructor.name.toString().replace "View", ""
        @data= {}

        @setHeader()
        @bindSockets()

        # Create announcements queue.
        @announcementsQueue = []
        @announcing = false

        # Call view `onReady` but only if present.
        @onReady() if @onReady?

        $.getJSON "/#{@viewId.toLowerCase()}/data", (data) =>
            for k, v of data
                @dataProcessor k, v if @dataProcessor?
                @data[k] = ko.observable v

            callback @data

    # Set active navigation and header properties.
    setHeader: =>
        currentPath = location.pathname.substring 1

        if currentPath isnt "/" and currentPath isnt ""
            $("#header").find(".#{currentPath}").addClass "active"

    # Create a KO compatible object based on the original `serverData` property.
    setData: (obj) =>
        @data = {} if not @data?
        @dataProcessor obj.key, obj.data if @dataProcessor?

        if @data[obj.key]?

            @data[obj.key] obj.data
        else
            @data[obj.key] = ko.observable obj.data

    # Helper to listen to socket events sent by the server. If no event name is
    # passed then use the view's default.
    bindSockets: =>
        @socketsName = "#{@viewId}Manager"

        # Listen to global sockets updates.
        ayla.sockets.on @socketsName + ".error", (err) => @announce err
        ayla.sockets.on @socketsName + ".result", (result) => @announce result
        ayla.sockets.on @socketsName + ".data", (obj) => @onData obj

    # DATA UPDATES
    # ----------------------------------------------------------------------

    # Updates data sent by the server.
    onData: (key, data) =>
        @setData key, data

# BIND BASE VIEW AND OPTIONS TO WINDOW
# --------------------------------------------------------------------------
window.ayla.BaseView = BaseView
