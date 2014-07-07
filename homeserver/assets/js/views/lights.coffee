# HOME LIGHTS VIEW
# --------------------------------------------------------------------------
class LightsView extends ayla.BaseView

    wrapperId: "lights"
    elements: ["button.state", "select.colorpicker"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dom["button.state"].click @lightToggle
        @dom["select.colorpicker"].colorpicker()

    # LIGHT CONTROL
    # ----------------------------------------------------------------------

    # Toggle lights om or off based on its current state.
    lightToggle: (e) =>
        console.warn e


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new LightsView()