# INDEX CONTROLLER
app =
    initialize: ->
        @bindEvents()
        return

    bindEvents: ->
        document.addEventListener "load", @onLoad, false
        document.addEventListener "deviceready", @onDeviceReady, false
        document.addEventListener "online", @onOnline, false
        document.addEventListener "offline", @onOffline, false
        return

    onLoad: ->
        return

    onDeviceReady: ->
        app.receivedEvent "deviceready"
        return

    onOnline: ->
        return

    onOffline: ->
        return

    receivedEvent: (id) ->
        parentElement = document.getElementById(id)
        listeningElement = parentElement.querySelector(".listening")
        receivedElement = parentElement.querySelector(".received")
        listeningElement.setAttribute "style", "display:none;"
        receivedElement.setAttribute "style", "display:block;"
        console.log "Received Event: " + id
        return
