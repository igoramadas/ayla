# EMAIL VIEW
# --------------------------------------------------------------------------
class EmailView extends ayla.BaseView

    viewId: "email"
    elements: [".emails"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        console.warn 1


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new EmailView()
