# SOCKETS
# --------------------------------------------------------------------------
class Sockets
    
    sobj = null

    # STARTING AND STOPPING
    # ----------------------------------------------------------------------

    # Start listening to Socket.IO messages from the server.
    init: ->
        if not sobj?
            url = window.location
            sobj = io.connect "https://#{url.hostname}:#{url.port}"

    # Stop listening to all socket messages from the server. Please note that this
    # will NOT kill the socket connection.
    stop: ->
        sobj.off()

    # SOCKET SHORTCUT METHODS
    # ----------------------------------------------------------------------

    # Bind a listener to the socket.
    on: (event, callback) ->
        sobj.on event, callback

    # Unbind a listener.
    off: (event, callback) ->
        sobj.off event, callback

    # Emit an event to the server.
    emit: (event, data) ->
        sobj.emit event, data


# BIND SOCKETS TO WINDOW.
# --------------------------------------------------------------------------
window.ayla.sockets = new Sockets()