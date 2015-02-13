# LIGHTS PAGE
# -----------------------------------------------------------------------------
class LightsView

    # Init the Lights View.
    init: =>

    # Dispose the Lights View.
    dispose: =>

    # Change hue light color.
    hueLightColor: (light, e) =>
        data = {lightId: light.id, title: light.title, colorHex: $(e.target).val()}

        sockets.emit "lightsmanager.hue.color", data

        return true

    # Toggle lights om or off based on its current state.
    hueLightToggle: (light, e) =>
        light.state = $(e.target).is ":checked"
        data = {lightId: light.id, title: light.title, state: light.state}

        sockets.emit "lightsmanager.hue.toggle", data

        return true

    # Toggle Ninja lights (these are actually power sockets).
    ninjaLightToggle: (light, e) =>
        code = if $(e.target).hasClass("success") then light.codeOn else light.codeOff
        data = {title: light.title, code: code}

        sockets.emit "lightsmanager.ninja.toggle", data

        return true

# BIND LIGHTS VIEW TO WINDOW
window.lightsView = new LightsView()
