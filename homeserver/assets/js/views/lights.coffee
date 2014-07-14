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
    hueLightToggle: (state, e) =>
        parentDiv = $ e.target.parentNode
        lightId = parentDiv.data "lightid"
        onOrOff = state.on ? false : true

        ayla.sockets.emit "lightsmanager.hue.toggle", {lightId: lightId, on: onOrOff}

    # Toggle Ninja lights (these are actually power sockets).
    ninjaLightToggle: (light, e) =>
        lightId = light.id

        ayla.sockets.emit "lightsmanager.ninja.toggle", {lightId: lightId}


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new LightsView()
