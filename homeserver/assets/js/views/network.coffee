# NETWORK VIEW
# --------------------------------------------------------------------------
class NetworkView extends ayla.BaseView

    viewId: "Network"

    # Init the Network view.
    onReady: =>
        logger "Loaded Network View"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.networkView = NetworkView
