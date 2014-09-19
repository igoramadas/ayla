# NETWORK VIEW
# --------------------------------------------------------------------------
class NetworkView extends ayla.BaseView

    viewId: "network"
    elements: ["table"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the Network view.
    onReady: =>
        @dom.table.dataTable ayla.optsDataDTables


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new NetworkView()
