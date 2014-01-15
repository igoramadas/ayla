# SYSTEM JOBS VIEW
# --------------------------------------------------------------------------
class SystemJobsView extends ayla.BaseView

    wrapperId: "system-jobs"
    elements: ["table"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dom.table.dataTable()


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new SystemJobsView()