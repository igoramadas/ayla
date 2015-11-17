# START VIEW
# --------------------------------------------------------------------------
class StartView extends ayla.BaseView

    viewId: "Start"

    mappingOptions:
        mappingOptions = {
            oauth: {
                create: (options) -> return ko.observable options.data
            },
            errors: {
                create: (options) -> return ko.observable options.data
            }
        }

    # Init the Start view.
    onReady: =>
        logger "Loaded Start View"

    # Redirect to API OAuth page.
    apiOAuthRedirect: (obj) =>
        if obj?.authenticated is false
            document.location.href = "/api/#{obj.id()}/auth"
        else
            return


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.startView = StartView
