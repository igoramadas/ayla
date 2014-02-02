# WEATHER MODEL
# --------------------------------------------------------------------------
# Represents weather conditions (indoors or outdoors).
class WeatherModel extends ayla.baseModel

    # CONSTRUCTOR AND PARSING
    # ----------------------------------------------------------------------

    # Construct a new weather model.
    constructor: (@originalData, @dataEventName) ->
        @text = ko.observable()
        @temperature = ko.observable()
        @humidity = ko.observable()
        @pressure = ko.observable()
        @co2 = ko.observable()

        @init "Weather", @originalData, @dataEventName

    # Parse weather data.
    setData: (data) =>
        @temperature data.temperature


# EXPORTS
# --------------------------------------------------------------------------
window.ayla.weatherModel = WeatherModel