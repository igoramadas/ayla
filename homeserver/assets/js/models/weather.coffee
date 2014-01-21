# WEATHER MODEL
# --------------------------------------------------------------------------
# Represents weather conditions (indoors or outdoors).
class WeatherModel extends ayla.baseModel

    # CONSTRUCTOR AND PARSING
    # ----------------------------------------------------------------------

    # Construct a new weather model.
    constructor: (@originalData) ->
        @temperature = ko.observable()
        @humidity = ko.observable()
        @pressure = ko.observable()
        @co2 = ko.observable()

        # Init model.
        @init @originalData

    # Set light model data.
    setData: (data) =>
        return if not data?

        @temperature @originalData.temperature
        @humidity @originalData.humidity
        @pressure @originalData.pressure
        @co2 @originalData.co2


# EXPORTS
# --------------------------------------------------------------------------
window.ayla.weatherModel = WeatherModel