# SETTINGS PAGE
window.settingsView =
    el: "#settings"

    init: =>
        @el.find("input.host").focus()

    dispose: =>
        app.debug @el, "Disposed"
