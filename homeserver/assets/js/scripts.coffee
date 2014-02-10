#= require lib/modernizr.js
#= require lib/jquery.js
#= require lib/jquery.jsonview.js
#= require lib/lodash.js
#= require lib/knockout.js
#= require lib/moment.js
#= require lib/datatables.js
#= require lib/placeholder.js
#= require lib/foundation.js
#= require sockets.coffee
#= require views/baseView.coffee

# Bind helper to log to console.
window.logger = -> console.log.apply console, arguments

# Start the app when document is ready and apply knockout bindings.
onReady = ->
        ayla.sockets.init() if ayla.sockets?
        ayla.currentView.init() if ayla.currentView?

# Hey ho let's go!
$(document).ready onReady