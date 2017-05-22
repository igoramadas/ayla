# SYSTEM VIEW
# --------------------------------------------------------------------------
class ManagerView extends ayla.BaseView

    viewId: "Manager"
    socketNames: []

    # Init the Manager view.
    onReady: =>
        logger "Loaded Manager View"

    # Process data, set endTime as moment instead of a number.
    modelProcessor: (key, data) =>
        logger "Received data", key

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.managerView = ManagerView
