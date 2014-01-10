# BASE VIEW
# --------------------------------------------------------------------------
class BaseView

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the view and set elements.
    init: =>
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


# BIND BASE VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.BaseView = BaseView