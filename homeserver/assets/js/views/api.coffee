# API VIEW
# --------------------------------------------------------------------------
class ApiView extends ayla.BaseView

    # Init the API modules list view.
    onReady: =>
        logger "Loaded API View"

        $(".module").click @onModuleClick

    # When user clicks or taps on a module, open the module page.
    onModuleClick: (e) =>
        src = $ e.currentTarget
        document.location.href = src.find("a").attr "href"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new ApiView()
