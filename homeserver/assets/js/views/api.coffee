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
            container.attr "id", key
            container.addClass "content"

            for data in arr
                timestamp = $ document.createElement "label"
                timestamp.html "Last update: " + moment(data.timestamp).format "lll"
                details = $ document.createElement "div"
                details.JSONView JSON.stringify(data.value)

                contents = $ document.createElement "div"
                contents.append timestamp
                contents.append details

                container.append contents

            link = $ document.createElement "a"
            link.html key
            link.attr "href", "##{key}"
            title = $ document.createElement "dd"
            title.append link

            @dom["tabs"].append title
            @dom["tabs-content"].append container



# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new ApiView()