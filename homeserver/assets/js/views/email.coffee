# EMAIL VIEW
# --------------------------------------------------------------------------
class EmailView extends ayla.BaseView

    # Init the Email view.
    onReady: =>
        logger "Loaded Email View"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.EmailView = EmailView
