# API MODULE VIEW
# --------------------------------------------------------------------------
class ApiView extends ayla.BaseView

    viewId: "Api"

    # Init the API detailed module view..
    onReady: =>
        logger "Loaded API View"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.apiView = ApiView
