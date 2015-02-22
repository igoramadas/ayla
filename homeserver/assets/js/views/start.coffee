# SYSTEM VIEW
# --------------------------------------------------------------------------
class StartView extends ayla.BaseView
    viewId: "Start"
    socketNames: []

    # Init the Start view.
    onReady: =>
        logger "Loaded Start View"

        $("#api .module").click @onModuleClick
        $("#system .tabs dd a").eq(0).click()

    # Dispose the Start view.
    onDispose: =>
        $("#api .module").unbind "click", @onModuleClick

    # Process data, set endTime as moment instead of a number.
    modelProcessor: (key, data) =>
        if key is "jobs"
            for job in data
                job.endTime = moment(job.endTime)

    # When user clicks or taps on a module, open the module page.
    onModuleClick: (e) =>
        src = $ e.currentTarget
        document.location.href = src.find("a").attr "href"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.startView = StartView
