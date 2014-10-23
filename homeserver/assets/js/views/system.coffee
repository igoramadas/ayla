# SYSTEM VIEW
# --------------------------------------------------------------------------
class SystemView extends ayla.BaseView

    viewId: "System"

    # Init the System view.
    onReady: =>
        logger "Loaded System View"

        $("#api .module").click @onModuleClick
        $("#api .tabs dd a").eq(0).click()

    # Dispose the System view.
    onDispose: =>
        $("#api .module").unbind "click", @onModuleClick

    # Process data, set endTime as moment instead of a number.
    dataProcessor: (key, data) =>
        if key is "jobs"
            for job in data
                job.endTime = moment(job.endTime)

    # When user clicks or taps on a module, open the module page.
    onModuleClick: (e) =>
        src = $ e.currentTarget
        document.location.href = src.find("a").attr "href"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.systemView = SystemView
