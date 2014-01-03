# STATUS VIEW
# --------------------------------------------------------------------------
class StatusView


    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the status view.
    init: =>
        @imps = ko.observableArray()
        @setupImps ayla.data.imps

    # Get list of registered imps from server and reset the imps list.
    setupImps: (arr) =>
        arr = JSON.parse(arr) if _.isString arr

        i.dispose for i in @imps()

        @imps.removeAll()
        @createImp i for i in arr

    # Create imp and add it to the imps list.
    createImp: (obj) =>
        return if not obj? or obj is ""

        imp = new ayla.impModel obj
        @imps.push imp


# BIND IMP MANAGER TO WINDOW
# --------------------------------------------------------------------------
window.ayla.statusView = new StatusView()