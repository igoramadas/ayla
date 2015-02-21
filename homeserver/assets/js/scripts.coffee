#= require lib/modernizr.js
#= require lib/jquery.js
#= require lib/jquery.cookie.js
#= require lib/lodash.js
#= require lib/knockout.js
#= require lib/moment.js
#= require lib/placeholder.js
#= require lib/fastclick.js
#= require lib/foundation.js
#= require lib/pager.js
#= require lib/crel.js
#= require lib/jsonhuman.js
#= require lib/ko.smartpage.js
#= require sockets.coffee
#= require indexview.coffee
#= require views/baseview.coffee
#= require views/email.coffee
#= require views/network.coffee
#= require views/system.coffee
#= require views/users.coffee

# Bind helper to log to console.
window.logger = -> console.log.apply console, arguments

# Start the app when document is ready and apply knockout bindings.
onReady = -> ayla.indexView.init()

# Hey ho let's go!
$(document).ready onReady
