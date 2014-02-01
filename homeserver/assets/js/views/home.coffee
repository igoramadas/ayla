# HOME VIEW
# --------------------------------------------------------------------------
class HomeView extends ayla.BaseView

    wrapperId: "home"
    elements: ["table", "td.state"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dom["td.state"].click @lightToggle
        @data.outdoor = @createModel "weather", "outdoor", "homemanager.outdoor"
        @data.livingroom = @createModel "room", "livingroom", "homemanager.livingroom"

    # Listen to important home events.
    bindEvents: =>

    # LIGHT CONTROL
    # ----------------------------------------------------------------------

    # Toggle lights om or off based on its current state.
    lightToggle: (e) =>
        console.warn e


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new HomeView()