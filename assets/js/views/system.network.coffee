# SYSTEM NETWORK VIEW
# --------------------------------------------------------------------------
class SystemNetworkView extends ayla.BaseView

    wrapperId: "system-network"
    elements: ["table"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dom.table.dataTable ayla.optsDataDTables


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new SystemNetworkView()