# MONEY VIEW
# --------------------------------------------------------------------------
class MoneyView extends ayla.BaseView

    wrapperId: "money"

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the Money view.
    onReady: =>
        @dataProcessor @data

    # Parse and process data coming from the server.
    dataProcessor: (key, data) =>
        if not data?
            data = key
            key = null

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new MoneyView()