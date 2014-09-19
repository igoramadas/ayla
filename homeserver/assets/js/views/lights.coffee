# HOME LIGHTS VIEW
# --------------------------------------------------------------------------
class LightsView extends ayla.BaseView

    wrapperId: "lights"
    elements: ["button.state", "select.colourpicker"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>

    # LIGHT CONTROL
    # ----------------------------------------------------------------------

    # Toggle lights om or off based on its current state.
    hueLightToggle: (light, e) =>
        state = not light.state

        ayla.sockets.emit "lightsManager.hue.toggle", {lightId: light.id, state: state}

        return true

    # Toggle Ninja lights (these are actually power sockets).
    ninjaLightToggle: (light, e) =>
        code = if $(e.target).hasClass("success") then light.codeOn else light.codeOff

        ayla.sockets.emit "lightsManager.ninja.toggle", {code: code}

        return true

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new LightsView()
