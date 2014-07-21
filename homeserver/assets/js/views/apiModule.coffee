# API VIEW
# --------------------------------------------------------------------------
class ApiView extends ayla.BaseView

    wrapperId: "api"
    elements: [".tabs", ".tabs-content"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the API data table.
    onReady: =>
        for key, arr of ayla.serverData
            container = $ document.createElement "div"
            container.attr "id", "data-#{key}"
            container.addClass "content"

            for data in arr
                filter = $ document.createElement "label"
                filter.html JSON.stringify data.filter
                timestamp = $ document.createElement "label"
                timestamp.html moment.unix(data.timestamp).format "lll"
                details = $ document.createElement "div"
                details.JSONView JSON.stringify(data.value)

                contents = $ document.createElement "div"
                contents.append filter
                contents.append timestamp
                contents.append details

                container.append contents

            link = $ document.createElement "a"
            link.html key
            link.attr "href", "#data-#{key}"
            title = $ document.createElement "dd"
            title.append link

            @dom["tabs"].append title
            @dom["tabs-content"].append container

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new ApiView()
