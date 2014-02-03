# HOME VIEW
# --------------------------------------------------------------------------
class HomeView extends ayla.BaseView

    wrapperId: "home"
    socketsName: "homemanager"
    elements: [".bedroom",".livingroom", ".kitchen", ".babyroom", ".outdoor", ".forecast"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        console.warn "ready"

    # LIGHT CONTROL
    # ----------------------------------------------------------------------

    # Toggle lights om or off based on its current state.
    lightToggle: (e) =>
        console.warn e


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new HomeView()