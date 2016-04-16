# BASE VIEW
# --------------------------------------------------------------------------
class BaseView

    # PROPERTIES
    # ----------------------------------------------------------------------

    # Holds main view data.
    model: {}
    mappingOptions: {}
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
        jsonUrl = location.pathname + "/data"

        $.getJSON jsonUrl.replace("//", ""), (data) =>
            @model = ko.mapping.fromJS data, @mappingOptions
            ko.applyBindings this

            @onReady()

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

    # Set active navigation and header properties.
    setHeader: =>
        currentPath = location.pathname.substring 1

        sepIndex = currentPath.indexOf "/"

        if sepIndex > 0
            currentPath = currentPath.substring 0, sepIndex

        if currentPath isnt "/" and currentPath isnt ""
            $("#header").find(".#{currentPath}").addClass "active"

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
