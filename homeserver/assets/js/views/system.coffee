# SYSTEM JOBS VIEW
# --------------------------------------------------------------------------
class SystemView extends ayla.BaseView

    viewId: "system"
    elements: ["table"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dom.table.dataTable()


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new SystemView()
