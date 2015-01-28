# SETTINGS PAGE
class SettingsView
    el: $ "#settings"

    init: =>
        @el.find("input.host").focus()

    dispose: =>
        app.debug @el, "Disposed"

window.settingsView = new SettingsView()
