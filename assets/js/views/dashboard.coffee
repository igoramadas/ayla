# DASHBOARD VIEW
# --------------------------------------------------------------------------
class DashboardView extends ayla.BaseView

    viewId: "Dashboard"

    # Init the Dashboard view.
    onReady: =>
        logger "Loaded Dashboard View"



# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.dashboardView = DashboardView
