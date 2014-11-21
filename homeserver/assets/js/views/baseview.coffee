# BASE VIEW
# --------------------------------------------------------------------------
class BaseView

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the view and set elements.
    init: (params, callback) =>
        ayla.indexView.pageInteraction()

        @viewIdLower = @viewId.toLowerCase()
        @model= {}

        @setHeader()
        @bindSockets()

        # Properly set URL depending on parameters.
        if params?.id?
            jsonUrl = "/#{@viewIdLower}/#{params.id}/data"
        else
            jsonUrl = "/#{@viewIdLower}/data"

        $.getJSON jsonUrl, (data) =>
            for k, v of data
                @modelProcessor k, v if @modelProcessor?
                @model[k] = ko.observable v

            callback @model

            # Call view `onReady` but only if present.
            @onReady() if @onReady?

    # Dispose the view, unbind events.
    dispose: =>
        ayla.sockets.off @socketsName + ".error", (err) => @announce err
        ayla.sockets.off @socketsName + ".result", (result) => @announce result
        ayla.sockets.off @socketsName + ".data", (obj) => @onData obj

        @onDispose() if @onDispose?

    # Set active navigation and header properties.
    setHeader: =>
        currentPath = location.pathname.substring 1

        if currentPath isnt "/" and currentPath isnt ""
            $("#header").find(".#{currentPath}").addClass "active"

    # DATA UPDATES
    # ----------------------------------------------------------------------

    # Helper to listen to socket events sent by the server. If no event name is
    # passed then use the view's default.
    bindSockets: =>
        @socketsName = "#{@viewId}Manager"

        # Listen to global sockets updates.
        ayla.sockets.on @socketsName + ".error", (err) => @announce err
        ayla.sockets.on @socketsName + ".result", (result) => @announce result
        ayla.sockets.on @socketsName + ".data", (obj) => @onData obj

    # Create a KO compatible object based on the original `serverData` property.
    setData: (obj) =>
        @model = {} if not @model?
        @modelProcessor obj.key, obj.data if @modelProcessor?

        if @model[obj.key]?
            @model[obj.key] obj.data
        else
            @model[obj.key] = ko.observable obj.data

    # Updates data sent by the server.
    onData: (key, data) =>
        @setData key, data

# BIND BASE VIEW AND OPTIONS TO WINDOW
# --------------------------------------------------------------------------
window.ayla.BaseView = BaseView
