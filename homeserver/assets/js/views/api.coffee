# API LIST VIEW
# --------------------------------------------------------------------------
class ApiView extends ayla.BaseView

    viewId: "api"
    elements: [".module"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the API data table.
    onReady: =>
        @dom["module"].click @onModuleClick

    # When user clicks or taps on a module, open the module page.
    onModuleClick: (e) =>
        src = $ e.currentTarget
        document.location.href = src.find("a").attr "href"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new ApiView()
