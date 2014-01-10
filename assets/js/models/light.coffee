# LIGHT MODEL
# --------------------------------------------------------------------------
# Represents a light bulb or lamp.
class LightModel extends ayla.baseModel

    # CONSTRUCTOR AND PARSING
    # ----------------------------------------------------------------------

    # Constructor will ask server for new data straight away.
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


# BIND LIGHT MODEL TO WINDOW
# --------------------------------------------------------------------------
window.ayla.lightModel = LightModel