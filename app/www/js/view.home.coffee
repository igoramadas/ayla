# HOME PAGE
# -----------------------------------------------------------------------------
class HomeView

    # Init the Settings View.
    init: =>
        @el.find("input.host").focus()

    # Dispose the Settings View.
    dispose: =>

# BIND HOME VIEW TO WINDOW
window.homeView = new HomeView()
