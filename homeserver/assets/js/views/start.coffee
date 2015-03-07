# SYSTEM VIEW
# --------------------------------------------------------------------------
class StartView extends ayla.BaseView

    viewId: "Start"
    socketNames: []

    # Init the Start view.
    onReady: =>
        logger "Loaded Start View"

    # Process data, set endTime as moment instead of a number.
    modelProcessor: (key, data) =>
        logger "Received data", key

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.startView = StartView
