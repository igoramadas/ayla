# LIGHT MODEL
# --------------------------------------------------------------------------
# Represents a light bulb or lamp.
class LightModel extends ayla.baseModel

    # CONSTRUCTOR AND PARSING
    # ----------------------------------------------------------------------

    # Constructs a new light model.
    constructor: (@originalData) ->
        @name = ko.observable()
        @reachable = ko.observable()
        @on = ko.observable()
        @hue = ko.observable()
        @bri = ko.observable()
        @sat = ko.observable()
        @stateClass = ko.computed => return (if @on then "on" else "off")

        # Init model.
        @init @originalData

    # Set light model data.
    setData: (data) =>
        return if not data?

        @name @originalData.name
        @reachable @originalData.reachable

        # Is it a Philips light or generic socket adapter?
        if @originalData.state?
            @on @originalData.state.on
            @hue @originalData.state.hue
            @bri @originalData.state.bri
            @sat @originalData.state.sat


# EXPORTS
# --------------------------------------------------------------------------
window.ayla.lightModel = LightModel