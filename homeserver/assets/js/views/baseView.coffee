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
        @viewName = @__proto__.constructor.name.toString()

        @setElements()
        @onReady() if @onReady?

    # This will iterate over the `elements` property to create the dom cache
    # and set the main wrapper based on the `wrapperId` property. The list
    # is optional, and can be used to add elements after the page has loaded.
    setElements: (list) =>
        if not @dom?
            @dom = {}
            @dom.wrapper = $ "#" + @wrapperId

        # Set default elements if list is not provided.
        list = @elements if not list?

        # Set elements cache.
        for s in list
            firstChar = s.substring 0, 1

            if firstChar is "#" or firstChar is "."
                domId = s.substring 1
            else
                domId = s

            @dom[domId] = @dom.wrapper.find s

    # Helper to create a model and automatically listen to data updates via sockets.
    # The data can be an object or the model id.
    createModel: (model, data, eventName) =>
        data = {id: data} if _.isString data
        modelObj = ayla["#{model}Model"]

        if modelObj?
            @data[data.id] = new modelObj data, eventName
        else
            logger @viewName, "createModel", model, "Invalid model type. Abort!"


# BIND BASE VIEW AND OPTIONS TO WINDOW
# --------------------------------------------------------------------------
window.ayla.BaseView = BaseView
window.ayla.optsDataDTables = {bAutoWidth: true, bInfo: false}