# EMAIL VIEW
# --------------------------------------------------------------------------
class EmailView extends ayla.BaseView

    viewId: "Email"

    # Init the Email view.
    onReady: =>
        logger "Loaded Email View"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.emailView = EmailView
