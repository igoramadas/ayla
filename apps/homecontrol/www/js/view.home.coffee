# HOME PAGE
# -----------------------------------------------------------------------------
class HomeView
    dataFields: ["weather", "lights", "ventilation"]

    # Init the Settings View.
    init: =>
        sockets.emit "data.get", arr

    # Dispose the Settings View.
    dispose: =>

# BIND HOME VIEW TO WINDOW
window.homeView = new HomeView()
