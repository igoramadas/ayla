# API VIEW
# --------------------------------------------------------------------------
class ApiView extends ayla.BaseView

    wrapperId: "api"
    elements: [".tabs", ".tabs-content"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the API data table.
    onReady: =>
        for key, data of ayla.serverData
            link = $ document.createElement "a"
            link.html key
            link.attr "href", "##{key}"

            title = $ document.createElement "dd"
            title.append link

            timestamp = $ document.createElement "label"
            timestamp.html "Last update: " + moment(data.timestamp).format "lll"
            details = $ document.createElement "div"
            details.JSONView JSON.stringify(data.value)

            contents = $ document.createElement "div"
            contents.attr "id", key
            contents.append timestamp
            contents.append details

            # Appoend to tab containers.
            @dom["tabs"].append title
            @dom["tabs-content"].append contents



# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new ApiView()