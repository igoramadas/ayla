# ROOM MODEL
# --------------------------------------------------------------------------
# Represents a room.
class RoomModel extends ayla.baseModel

    # CONSTRUCTOR AND PARSING
    # ----------------------------------------------------------------------

    # Construct a new room model.
    constructor: (@originalData, @dataEventName) ->
        @title = ko.observable()
        @weather = ko.observable()
        @lights = ko.observable()

        @init @originalData, @dataEventName

    # Parse room data.
    setData: (data) =>
        @title data.title


# EXPORTS
# --------------------------------------------------------------------------
window.ayla.roomModel = RoomModel
