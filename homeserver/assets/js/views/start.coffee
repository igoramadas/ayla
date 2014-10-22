# START VIEW
# --------------------------------------------------------------------------
class StartView extends ayla.BaseView

    viewId: "Start"

    # Init the Start view.
    onReady: =>
        logger "Loaded Start View"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.StartView = StartView
