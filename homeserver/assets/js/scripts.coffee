#= require lib/jquery.js
#= require lib/jquery.cookie.js
#= require lib/lodash.js
#= require lib/knockout.js
#= require lib/ko.mapping.js
#= require lib/moment.js
#= require lib/what-input.js
#= require lib/foundation.js
#= require lib/crel.js
#= require lib/jsonhuman.js
#= require sockets.coffee
#= require views/baseview.coffee
#= require views/api.coffee
#= require views/dashboard.coffee
#= require views/manager.coffee
#= require views/start.coffee

# Bind helper to log to console.
window.logger = -> console.log.apply console, arguments

# Hey ho let's go!
$(document).ready ->
    viewId = location.pathname.substr 1

    if viewId is ""
        viewId = "start"
    else if viewId.indexOf("/") > 0
        viewId = viewId.substr(0, viewId.indexOf("/"))

    ayla.currentView = new ayla[viewId + "View"]
    ayla.currentView.init()
