# USERS VIEW
# --------------------------------------------------------------------------
class UsersView extends ayla.BaseView

    viewId: "Users"

    # Init the Users view.
    onReady: =>
        logger "Loaded Users View"

    # Parse and process data coming from the server.
    dataProcessor: (key, data) =>
        if not data?
            data = key
            key = null

        # Add onlineCss property to user objects, and make sure
        # the "guest" property is set on users list.
        if key isnt "users" and key isnt "bluetoothDevices"
            if data.online? and not data.onlineCss?
                data.onlineCss = ko.computed ->
                    if data.online is true or data.online is "true"
                        return "online"
                    else
                        return "offline"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.UsersView = UsersView
