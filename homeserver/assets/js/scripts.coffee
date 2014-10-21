#= require lib/modernizr.js
#= require lib/jquery.js
#= require lib/jquery.cookie.js
#= require lib/jquery.colorpicker.js
#= require lib/lodash.js
#= require lib/knockout.js
#= require lib/ko.colorpicker.js
#= require lib/moment.js
#= require lib/placeholder.js
#= require lib/fastclick.js
#= require lib/foundation.js
#= require lib/pager.js
#= require lib/chart.js
#= require lib/crel.js
#= require lib/jsonhuman.js
#= require sockets.coffee
#= require views/index.coffee
#= require views/baseview.coffee
#= require views/users.coffee
#= require views/weather.coffee

# Bind helper to log to console.
window.logger = ->
    console.log.apply console, arguments

# Start the app when document is ready and apply knockout bindings.
onReady = ->
    ayla.indexView.init()

# Hey ho let's go!
$(document).ready onReady
