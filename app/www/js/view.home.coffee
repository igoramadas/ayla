# SETTINGS PAGE
class HomeView
    init: =>
        @el.find("input.host").focus()

    dispose: =>

window.homeView = new HomeView()
