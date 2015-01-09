# FITNESS VIEW
# --------------------------------------------------------------------------
class FitnessView extends ayla.BaseView

    viewId: "Fitness"

    # Init the Fitness view.
    onReady: =>
        logger "Loaded Fitness View"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.fitnessView = FitnessView
