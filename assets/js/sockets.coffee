# SOCKETS
# --------------------------------------------------------------------------
class Sockets

    # The Socket.IO object.
    socket: null


    # STARTING AND STOPPING
    # ----------------------------------------------------------------------

    # Start listening to Socket.IO messages from the server.
    init: =>
        if not @socket?
            url = window.location
            @socket = io.connect "http://#{url.hostname}:#{url.port}"

    # Stop listening to all socket messages from the server. Please note that this
    # will NOT kill the socket connection.
    stop: =>
        @socket.off()


    # SOCKET SHORTCUT METHODS
    # ----------------------------------------------------------------------

    # Bind a listener to the socket.
    on: (event, callback) =>
        @socket.on event, callback

    # Unbind a listener.
    off: (event, callback) =>
        @socket.off event, callback

    # Emit an event to the server.
    emit: (event, data) =>
        @socket.emit event, data


# BIND SOCKETS TO WINDOW.
# --------------------------------------------------------------------------
window.jarbas.sockets = new Sockets()