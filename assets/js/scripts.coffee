#= require lib/jquery.js
#= require lib/lodash.js
#= require lib/knockout.js
#= require lib/moment.js

#= require views/alertsView.coffee
#= require views/statusView.coffee
#= require sockets.coffee

# Bind helper to log to console.
window.logger = -> console.log.apply console, arguments

# Start the app when document is ready and apply knockout bindings.
onReady = ->
    $.get "/data", (data) ->
        jarbas.data = data
        jarbas.settings = data.settings
        jarbas.alerts.init()
        jarbas.sockets.init()

        if document.location.href.indexOf("rooms") < 1
            jarbas.statusView.init()
            ko.applyBindings jarbas.statusView
        else
            jarbas.roomsView.init()
            ko.applyBindings jarbas.roomsView


# Hey ho let's go!
$(document).ready onReady