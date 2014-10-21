# INDEX VIEW
# --------------------------------------------------------------------------
class IndexView

    # PROPERTIES
    # ----------------------------------------------------------------------

    # Holds view data.
    data: {}

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Bind a page to the main view.
    bindPage: (viewId) =>
        ayla.currentView.onDispose() if ayla.currentView?.onDispose?

        return (callback) ->
            ayla.currentView = new ayla[viewId + "View"]()
            ayla.currentView.init callback

    # Init the view and set elements.
    init: =>
        $(document).foundation()
        Chart.defaults.global.responsive = true

        ayla.sockets.init()

        pager.extendWithPage this
        ko.applyBindings this
        pager.start this

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
