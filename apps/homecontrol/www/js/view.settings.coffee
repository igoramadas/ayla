# SETTINGS PAGE
# -----------------------------------------------------------------------------
class SettingsView

    # Init the Settings View.
    init: =>
        @el.find("button.save").click @saveClick

    # Dispose the Settings View.
    dispose: =>

    # When user clicks the "Save" button.
    saveClick: (e) =>
        host = @el.find("input.host").val()
        port = @el.find("input.port").val()
        token = @el.find("input.token").val()

        url = "https://#{host}:#{port}/tokenrequest?token=#{token}"

        $.getJSON url, (data) =>

            console.warn data

            localStorage.setItem "homeserver_url", "https://#{host}:#{port}/"
            localStorage.setItem "homeserver_token", token



# BIND SETTINGS VIEW TO WINDOW
window.settingsView = new SettingsView()
