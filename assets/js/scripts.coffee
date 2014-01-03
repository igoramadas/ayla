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
        ayla.data = data
        ayla.settings = data.settings
        ayla.alerts.init()
        ayla.sockets.init()

        if document.location.href.indexOf("rooms") < 1
            ayla.statusView.init()
            ko.applyBindings ayla.statusView
        else
            ayla.roomsView.init()
            ko.applyBindings ayla.roomsView


# Hey ho let's go!
$(document).ready onReady