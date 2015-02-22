# BASE VIEW
# --------------------------------------------------------------------------
class BaseView

    # PROPERTIES
    # ----------------------------------------------------------------------

    # Holds main view data.
    model: {}
    lastUserInteraction: moment().unix()

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the view and set elements.
    init: =>
        $(document).foundation()

        @setSockets()
        @setAnnouncements()
        @setHeader()

        # Get URL for data.
        jsonUrl = location.pathname.substring(1) + "/data"

        $.getJSON jsonUrl, (data) =>
            @setModel data
            ko.applyBindings @model

    # Create announcements queue.
    setAnnouncements: =>
        @announcementsQueue = []
        @announcing = false

    # Helper to listen to socket events sent by the server. If no event name is
    # passed then use the view's default.
    setSockets: =>
        ayla.sockets.init()

        ayla.sockets.on "server.info", (info) =>
            ayla.server.info = info

        for s in @socketNames
            ayla.sockets.on "#{s}.error", (err) => @announce err
            ayla.sockets.on "#{s}.result", (result) => @announce result
            ayla.sockets.on "#{s}.data", (obj) => @onData obj

    # Set active navigation and header properties.
    setHeader: =>
        currentPath = location.pathname.substring 1

        if currentPath isnt "/" and currentPath isnt ""
            $("#header").find(".#{currentPath}").addClass "active"

    # DATA UPDATES
    # ----------------------------------------------------------------------

    # Create a KO compatible object based on the original `serverData` property.
    setModel: (obj) =>
        @model = {} if not @model?
        @modelProcessor obj.key, obj.data if @modelProcessor?

        if @model[obj.key]?
            @model[obj.key] obj.data
        else
            @model[obj.key] = ko.observable obj.data

    # Updates data sent by the server.
    onData: (key, data) =>
        @setModel key, data

    # Listen to main sockets (server, settings, modules etc).
    bindSockets: =>


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
