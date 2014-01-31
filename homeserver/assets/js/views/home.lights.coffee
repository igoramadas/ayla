# HOME LIGHTS VIEW
# --------------------------------------------------------------------------
class HomeLightsView extends ayla.BaseView

    wrapperId: "home-lights"
    elements: ["table", "td.state"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dom["td.state"].click @lightToggle

    # LIGHT CONTROL
    # ----------------------------------------------------------------------

    # Toggle lights om or off based on its current state.
    lightToggle: (e) =>
        console.warn e


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new HomeLightsView()