# BASE VIEW
# -----------------------------------------------------------------------------
class BaseView

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds main view data.
    model: {}
    mappingOptions: {}
    lastUserInteraction: moment().unix()

    # MAIN METHODS
    # -------------------------------------------------------------------------

    # Init the view and set elements.
    init: =>
        $(document).foundation()

        # Create Vue router and app.
        @router = new VueRouter {routes: noidm.routes}
        @vue = new Vue {router: @router, data: {error: null, pageTitle: ""}}
        @vue.$mount "#app"

        # Connect to sockets.
        @socket = io()

    # DATA METHODS
    # -------------------------------------------------------------------------

    # Fetch (GET) data from the server.
    fetchData: (path, data) ->
        return new Promise (resolve, reject) ->
            try
                result = await $.getJSON "/api/#{path}"
                resolve result
            catch ex
                logger.error "App.fetchData", path, ex
                reject ex

    # Post data to the server.
    postData: (path, data) ->
        return new Promise (resolve, reject) ->
            try
                options = {
                    url: "/api/#{path}"
                    data: data
                }
                result = await $.post options
                resolve result
            catch ex
                logger.error "App.postData", path, ex
                reject ex

# BIND BASE VIEW AND OPTIONS TO WINDOW
# --------------------------------------------------------------------------
window.ayla.BaseView = BaseView
