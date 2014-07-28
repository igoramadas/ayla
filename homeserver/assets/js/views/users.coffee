# USERS VIEW
# --------------------------------------------------------------------------
class UsersView extends ayla.BaseView

    wrapperId: "users"

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the Users view.
    onReady: =>
        @dataProcessor @data

    # Parse and process data coming from the server.
    dataProcessor: (key, data) =>
        if not data?
            data = key
            key = null

        for username, user of @data
            if _.isFunction user
                userdata = user()
                do (userdata) =>
                    if username isnt "users" and userdata.online? and not userdata.onlineCss?
                        online = if _.isFunction userdata.online then userdata.online() else userdata.online
                        userdata.onlineCss = ko.computed ->
                            if online
                                return "on"
                            else
                                return "off"

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new UsersView()
