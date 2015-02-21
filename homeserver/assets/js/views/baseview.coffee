# BASE VIEW
# --------------------------------------------------------------------------
class BaseView

    # PROPERTIES
    # ----------------------------------------------------------------------

    # Holds main view data.
    data: {}
    lastUserInteraction: moment().unix()

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the view and set elements.
    init: =>
        ayla.indexView.pageInteraction()

        $(document).foundation()

        # Init sockets.
        ayla.sockets.init()
        @bindSockets()

        # Create announcements queue.
        @announcementsQueue = []
        @announcing = false

        # Add timeout to refresh window after one day (also dependant on mouse movement).
        setTimeout @pageRefresh, 86400

        # Init pager.js and knockout.js.
        ko.applyBindings this


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






    # Listen to main sockets (server, settings, modules etc).
    bindSockets: =>
        ayla.sockets.on "server.info", (info) =>
            ayla.server.info = info

    # Bind a page to the main view.
    bindPage: (callback, page) =>
        ayla.currentView.dispose() if ayla.currentView?

        page.currentId = "system" if page.currentId is ""

        ayla.currentView = new ayla[page.currentId + "View"]()
        ayla.currentView.init page.pageRoute.params, callback

    # Highlight tab when clicked or tapped.
    setPageTab: (e) =>
        src = $ ".tab-#{e.page.currentId}"
        src.parent().find("dd").removeClass "active"
        src.addClass "active"

    # Helper to refresh the page once a day, after there has been no user interaction for at
    # least 30 minutes. Quick and dirty hack to clear memory leaks.
    pageRefresh: =>
        if moment().unix() - @lastUserInteraction > 1800
            document.location.reload()
        else
            setTimeout @pageRefresh, 300

    # Helper to set the lastUserInteraction timestamp.
    pageInteraction: =>
        @lastUserInteraction = moment().unix()

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
