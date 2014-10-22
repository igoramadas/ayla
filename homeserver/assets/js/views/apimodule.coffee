# API MODULE VIEW
# --------------------------------------------------------------------------
class ApiModuleView extends ayla.BaseView

    # Init the API detailed module view..
    onReady: =>
        logger "Loaded API Module View"

        containers = $ ".data-table"

        # Iterate all data tables and transform JSON to readable tables.
        $.each containers, (i, d) ->
            try
                div = $ d
                html = div.html()
                json = JSON.parse html
                div.html JsonHuman.format json
            catch ex
                console.warn "Could not parse JSON.", html

        $("dd a").eq(0).click()

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.ApiModuleView = ApiModuleView
