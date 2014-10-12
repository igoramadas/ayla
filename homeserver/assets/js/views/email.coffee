# EMAIL VIEW
# --------------------------------------------------------------------------
class EmailView extends ayla.BaseView

    viewId: "email"
    elements: [".emails"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dataProcessor @data

    # Parse and process data coming from the server.
    dataProcessor: (data) =>
        console.warn data

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new EmailView()
