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

        @setSockets()

        # Create Vue router and app.
        @router = new VueRouter {routes: noidm.routes}
        @vue = new Vue {router: @router, data: {error: null, pageTitle: ""}}
        @vue.$mount "#app"

        # Connect to sockets.
        @socket = io {query: {token: token}}

    # Helper to listen to socket events sent by the server. If no event name is
    # passed then use the view's default.
    setSockets: =>
        ayla.sockets.init()

        ayla.sockets.on "server.info", (info) =>
            ayla.server.info = info

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
