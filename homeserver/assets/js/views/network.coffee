# SYSTEM NETWORK VIEW
# --------------------------------------------------------------------------
class NetworkView extends ayla.BaseView

    wrapperId: "network"
    elements: ["table"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dom.table.dataTable ayla.optsDataDTables


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new NetworkView()