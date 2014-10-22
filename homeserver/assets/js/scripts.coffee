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
#= require indexview.coffee
#= require views/baseview.coffee
#= require views/api.coffee
#= require views/apimodule.coffee
#= require views/email.coffee
#= require views/fitness.coffee
#= require views/lights.coffee
#= require views/money.coffee
#= require views/network.coffee
#= require views/start.coffee
#= require views/system.coffee
#= require views/users.coffee
#= require views/weather.coffee

# Bind helper to log to console.
window.logger = -> console.log.apply console, arguments

# Start the app when document is ready and apply knockout bindings.
onReady = -> ayla.indexView.init()

# Hey ho let's go!
$(document).ready onReady
