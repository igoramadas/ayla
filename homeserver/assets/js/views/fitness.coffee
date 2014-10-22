# FITNESS VIEW
# --------------------------------------------------------------------------
class FitnessView extends ayla.BaseView

    # Init the Fitness view.
    onReady: =>
        logger "Loaded Fitness View"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.FitnessView = FitnessView
