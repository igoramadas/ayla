# SETTINGS PAGE
class SettingsView
    init: =>
        @el.find("input.host").focus()

    dispose: =>

window.settingsView = new SettingsView()
