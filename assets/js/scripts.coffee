#= require lib/jquery.js
#= require lib/lodash.js
#= require lib/knockout.js
#= require lib/moment.js
#= require lib/datatables.js

#= require models/baseModel.coffee
#= require models/light.coffee
#= require models/room.coffee
#= require views/baseView.coffee
#= require sockets.coffee

# Bind helper to log to console.
window.logger = -> console.log.apply console, arguments

# Start the app when document is ready and apply knockout bindings.
onReady = ->
        if ayla.currentView?
            ayla.currentView.init()

# Hey ho let's go!
$(document).ready onReady