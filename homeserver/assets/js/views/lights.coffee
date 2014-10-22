# HOME LIGHTS VIEW
# --------------------------------------------------------------------------
class LightsView extends ayla.BaseView

    viewId: "lights"

    # Init the Lights view.
    onReady: =>
        logger "Loaded Lights View"

    # Change hue light color.
    hueLightColor: (light, e) =>
        data = {lightId: light.id, title: light.title, colorHex: $(e.target).val()}

        ayla.sockets.emit "#{@socketsName}.Hue.color", data

        return true

    # Toggle lights om or off based on its current state.
    hueLightToggle: (light, e) =>
        light.state = $(e.target).is ":checked"
        data = {lightId: light.id, title: light.title, state: light.state}

        ayla.sockets.emit "#{@socketsName}.Hue.toggle", data

        return true

    # Toggle Ninja lights (these are actually power sockets).
    ninjaLightToggle: (light, e) =>
        code = if $(e.target).hasClass("success") then light.codeOn else light.codeOff
        data = {title: light.title, code: code}

        ayla.sockets.emit "#{@socketsName}.Ninja.toggle", data

        return true

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.LightsView = LightsView
