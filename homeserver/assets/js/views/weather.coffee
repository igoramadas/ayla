# HOME VIEW
# --------------------------------------------------------------------------
class WeatherView extends ayla.BaseView

    wrapperId: "weather"
    elements: [".bedroom",".livingroom", ".kitchen", ".babyroom", ".outdoor", ".forecast"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dataProcessor @data

    # Parse and process data coming from the server.
    dataProcessor: (data) =>
        if data.condition?
            condition = if _.isFunction data.condition then data.condition() else data.condition
            data.conditionCss = ko.computed ->
                return condition.toLowerCase().replace(/\s/g, "-")

    # LIGHT CONTROL
    # ----------------------------------------------------------------------

    # Toggle lights om or off based on its current state.
    lightToggle: (e) =>
        console.warn e


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new WeatherView()