# INDEX VIEW
# --------------------------------------------------------------------------
class IndexView

    # PROPERTIES
    # ----------------------------------------------------------------------

    # Holds main view data.
    data: {}
    lastUserInteraction: moment().unix()

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the view and set elements.
    init: =>
        $(document).foundation()
        Chart.defaults.global.responsive = true
        Chart.defaults.global.scaleFontColor = "rgb(252, 252, 252)"

        # Init sockets.
        ayla.sockets.init()
        @bindSockets()

        # Create announcements queue.
        @announcementsQueue = []
        @announcing = false

        # Add timeout to refresh window after one day (also dependant on mouse movement).
        setTimeout @pageRefresh, 86400
        $(document).mousemove @globalMouseMove

        # Init pager.js and knockout.js.
        pager.extendWithPage this
        ko.applyBindings this
        pager.start()

    # Listen to main sockets (server, settings, modules etc).
    bindSockets: =>
        ayla.sockets.on "server.settings", (settings) =>
            ayla.server.settings = settings
        ayla.sockets.on "server.result", (modules, disabledModules) =>
            ayla.server.api.modules = modules
            ayla.server.api.disabledModules = disabledModules
        ayla.sockets.on "server.manager", (modules) =>
            ayla.server.manager.modules = modules

    # Bind a page to the main view.
    bindPage: (callback, page) =>
        ayla.currentView.dispose() if ayla.currentView?

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
window.ayla.indexView = new IndexView()
