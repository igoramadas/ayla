# API VIEW
# --------------------------------------------------------------------------
class ApiView extends ayla.BaseView

    wrapperId: "api"
    elements: [".apidata"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the API data table.
    onReady: =>
        @dom.apidata.JSONView ayla.serverData


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new ApiView()