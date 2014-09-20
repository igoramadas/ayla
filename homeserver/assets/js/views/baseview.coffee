# BASE VIEW
# --------------------------------------------------------------------------
class BaseView

    # PROPERTIES
    # ----------------------------------------------------------------------

    # Holds view data.
    data: {}

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the view and set elements.
    init: =>
        @setElements()
        @setHeader()
        @setData()
        @bindSockets()

        # Create announcements queue.
        @announcementsQueue = []
        @announcing = false

        # Call view `onReady` but only if present.
        @onReady() if @onReady?

        # Knockout.js bindings.
        ko.applyBindings @data if @data?

    # This will iterate over the `elements` property to create the dom cache
    # and set the main wrapper based on the `viewId` property. The list
    # is optional, and can be used to add elements after the page has loaded.
    setElements: (list) =>
        if not @dom?
            @dom = {}

            if @viewId
                @dom.wrapper = $ "#" + @viewId
            else
                @dom.wrapper = $ "#contents"

        # Set default elements if list is not provided.
        list = @elements if not list?

        return if not list?

        # Set elements cache.
        for s in list
            firstChar = s.substring 0, 1

            if firstChar is "#" or firstChar is "."
                domId = s.substring 1
            else
                domId = s

            @dom[domId] = @dom.wrapper.find s

        # Set announcement element.
        @dom.announcements = $ "#announcements"

    # Set active navigation and header properties.
    setHeader: =>
        $(document).foundation()

        currentPath = location.pathname.substring 1
        if currentPath isnt "/" and currentPath isnt ""
            $("nav").find(".#{currentPath}").addClass "active"

    # Create a KO compatible object based on the original `serverData` property.
    setData: (obj) =>
        @data = {} if not @data?

        if not obj?
            for k, v of ayla.serverData
                @dataProcessor k, v if @dataProcessor?
                @data[k] = ko.observable v
        else
            @dataProcessor obj.key, obj.data if @dataProcessor?

            if @data[obj.key]?

                @data[obj.key] obj.data
            else
                @data[obj.key] = ko.observable obj.data

    # Helper to listen to socket events sent by the server. If no event name is
    # passed then use the view's default.
    bindSockets: =>
        socketsId = @viewId.charAt(0).toUpperCase() + @viewId.slice 1;
        @socketsName = "#{socketsId}Manager" if not @socketsName?

        # Listen to global sockets updates.
        ayla.sockets.on @socketsName + ".error", (err) => @announce err
        ayla.sockets.on @socketsName + ".result", (result) => @announce result
        ayla.sockets.on @socketsName + ".data", (obj) => @onData obj

    # DATA UPDATES
    # ----------------------------------------------------------------------

    # Updates data sent by the server.
    onData: (key, data) =>
        @setData key, data

    # ANNOUNCEMENTS
    # ----------------------------------------------------------------------

    # Show bottom announcement.
    announce: (obj) =>
        @announcementsQueue.push obj
        @nextAnnouncement()

    # Show next announcement.
    nextAnnouncement: =>
        return if @announcing or @announcementsQueue.length < 1

        obj = @announcementsQueue.shift()

        if obj.err?
            css = "error"
            timeout = 3000
        else if obj.result? and obj.important
            css = "ok"
            timeout = 1600
        else
            return @nextAnnouncement()

        # Set announcing and remove color classes.
        @announcing = true
        @dom.announcements.removeClass "error"
        @dom.announcements.removeClass "ok"
        @dom.announcements.addClass css

        # Update announcement element.
        @dom.announcements.find(".message").html obj.message
        @dom.announcements.fadeIn 200, =>
            hideFunc = =>
                @dom.announcements.fadeOut 200, =>
                    @announcing = false
                    @nextAnnouncement()

            _.delay hideFunc, timeout

# BIND BASE VIEW AND OPTIONS TO WINDOW
# --------------------------------------------------------------------------
window.ayla.BaseView = BaseView
window.ayla.optsDataDTables = {bAutoWidth: true, bInfo: false}
