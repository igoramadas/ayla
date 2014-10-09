# API VIEW
# --------------------------------------------------------------------------
class ApiModuleView extends ayla.BaseView

    viewId: "apimodule"

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the API data table.
    onReady: =>
        for key, data of ayla.serverData
            containers = $ "#data-#{key} .data-table"
            $.each containers, (i, d) ->
                div = $ d
                json = JSON.parse div.html()
                div.html JsonHuman.format json

        $("dd a").eq(0).click()

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new ApiModuleView()
