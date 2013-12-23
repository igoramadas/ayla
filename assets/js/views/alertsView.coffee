# ALERTS
# --------------------------------------------------------------------------
class AlertsView

    # All alerts are added to a queue.
    queue = []


    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the Alerts manager / view.
    init: =>
        @$el = $ "#alerts"
        @$title = @$el.find ".title"
        @$message = @$el.find ".message"
        @height = @$el.outerHeight()

    # Show a neutral info alert.
    info: (obj) =>
        logger "Alert", "info", obj
        obj.type = "info"
        queue.push obj
        @next()

    # Show an error alert.
    error: (obj) =>
        logger "Alert", "error", obj
        obj.type = "error"
        queue.push obj
        @next()


    # INTERNAL IMPLEMENTATION
    # ----------------------------------------------------------------------

    # Gets the next alert to be displayed.
    next: =>
        return if queue.length < 1
        alertObj = queue.shift()
        @show alertObj

    # Show the passed alert to the user.
    show: (alertObj) =>
        @$title.html alertObj.title
        @$message.html alertObj.message
        @$el.addClass(alertObj.type).animate {top: 0}
        setTimeout @hide, jarbas.settings.alerts.hideTimeout

    # Hide the current alert.
    hide: =>
        @$el.animate {top: @height * -1}, =>
            @$el.removeClass("info").removeClass("error")


# BIND ALERTS TO WINDOW
# --------------------------------------------------------------------------
window.jarbas.alerts = new AlertsView()