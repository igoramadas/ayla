# SETTINGS PAGE
class HomeView
    el: $ "#home"

    init: =>
        @el.find("input.host").focus()

    dispose: =>
        app.debug @el, "Disposed"

window.homeView = new HomeView()
