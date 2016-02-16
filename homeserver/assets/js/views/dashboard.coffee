# DASHBOARD VIEW
# --------------------------------------------------------------------------
class DashboardView extends ayla.BaseView

    viewId: "Dashboard"

    mappingOptions:
        mappingOptions = {
            oauth: {
                create: (options) -> return ko.observable options.data
            },
            errors: {
                create: (options) -> return ko.observable options.data
            }
        }

    # Init the Dashboard view.
    onReady: =>
        logger "Loaded Dashboard View"

    # Redirect to API OAuth page.
    apiOAuthRedirect: (obj) =>
        console.warn obj
        if obj?.oauth?().authenticated is false
            document.location.href = "/api/#{obj.id()}/auth"
        else
            return


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.dashboardView = DashboardView
