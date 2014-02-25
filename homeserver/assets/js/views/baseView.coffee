# BASE VIEW
# --------------------------------------------------------------------------
class BaseView

    # PROPERTIES
    # ----------------------------------------------------------------------

    # Holds view data.
    data: {}

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the view and set elements.
    init: =>
        @setElements()
        @setHeader()
        @setData()
        @bindSockets()

        # Call view `onReady` if present.
        @onReady() if @onReady?

        # Knockout.js bindings.
        ko.applyBindings @data if @data?

    # This will iterate over the `elements` property to create the dom cache
    # and set the main wrapper based on the `wrapperId` property. The list
    # is optional, and can be used to add elements after the page has loaded.
    setElements: (list) =>
        if not @dom?
            @dom = {}
            @dom.wrapper = $ "#" + @wrapperId

        # Set default elements if list is not provided.
        list = @elements if not list?

        return if not list?

        # Set elements cache.
        for s in list
            firstChar = s.substring 0, 1

            if firstChar is "#" or firstChar is "."
                domId = s.substring 1
            else
                domId = s

            @dom[domId] = @dom.wrapper.find s

    # Set active navigation and header properties.
    setHeader: =>
        currentPath = location.pathname.substring 1
        $("nav").find(".#{currentPath}").addClass "active"
        $(document).foundation()

    # Create a KO compatible object based on the original `serverData` property.
    setData: =>
        @data = {}
        return if not ayla.serverData?

        # Iterate passed data and populate the view's data property.
        for key, value of ayla.serverData
            @dataProcessor value if @dataProcessor?
            @data[key] = ko.observable value

    # Helper to listen to socket events sent by the server. If no event name is
    # passed then use the view's default.
    bindSockets: =>
        return if not @socketsName?

        # Listen to global sockets updates.
        ayla.sockets.on @socketsName, (data) => @onData data

        # Listen to socket updates for each data property.
        for key, value of @data
            do (key) =>
                e = @socketsName + "." + key
                ayla.sockets.on e, (data) => @onData data, key

    # DATA UPDATES
    # ----------------------------------------------------------------------

    # Updates data sent by the server. A property can be passed so it will
    # update data for that particular property, otherwise assume it's the full data object.
    onData: (data, property) =>
        if property?
            @dataProcessor data if @dataProcessor?
            @data[property] data
        else
            @setData data


# BIND BASE VIEW AND OPTIONS TO WINDOW
# --------------------------------------------------------------------------
window.ayla.BaseView = BaseView
window.ayla.optsDataDTables = {bAutoWidth: true, bInfo: false}