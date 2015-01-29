# SOCKETS
# -----------------------------------------------------------------------------
class Sockets

    conn = null

    # Start listening to Socket.IO messages from the server.
    init: ->
        url = localStorage.getItem "homeserver_url"

        if url?
            conn = io.connect "#{url.protocol}//#{url.hostname}:#{url.port}"

    # Stop listening to all socket messages from the server. Please note that this
    # will NOT kill the socket connection.
    stop: ->
        conn.off()

    # Bind a listener to the socket.
    on: (event, callback) ->
        conn.on event, callback

    # Unbind a listener.
    off: (event, callback) ->
        conn.off event, callback

    # Emit an event to the server.
    emit: (event, data) ->
        conn.emit event, data

# BIND SOCKETS TO WINDOW
window.sockets = new Sockets()
