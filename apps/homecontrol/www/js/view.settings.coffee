# SETTINGS PAGE
# -----------------------------------------------------------------------------
class SettingsView

    # Init the Settings View.
    init: =>
        @el.find("form").on "valid", @saveClick

    # Dispose the Settings View.
    dispose: =>

    # When user clicks the "Save" button.
    saveClick: (e) =>
        serverResult = @el.find ".server-result"
        host = @el.find("input.host").val()
        port = @el.find("input.port").val()
        token = @el.find("input.token").val()

        url = "http://#{host}:#{port}/tokenrequest?token=#{token}"

        # Try to get token info from server.
        xhr = $.getJSON url, (data) =>
            if data.error?
                serverResult.html "Invalid token or server details."
            else
                localStorage.setItem "homeserver_url", "https://#{host}:#{port}/"
                localStorage.setItem "homeserver_token", token
                serverResult.html "Authenticated till " + data.result.expires

        xhr.fail =>
            serverResult.html "Could not contact the specified server."

# BIND SETTINGS VIEW TO WINDOW
window.settingsView = new SettingsView()
