# WEATHER VIEW
# --------------------------------------------------------------------------
class WeatherView extends ayla.BaseView

    wrapperId: "weather"

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the Weather view.
    onReady: =>
        @dataProcessor @data

    # Parse and process data coming from the server. Weather data will be appended
    # directly to the rooms object. If only one argument is passed, assume it's the data.
    dataProcessor: (key, data) =>
        if not data?
            data = key
            key = null

        @data.indoorAvg = ko.observable() if not @data.indoorAvg?

        # Incoming data has condition property? If so, set its css computed value.
        if data.condition?
            condition = if _.isFunction data.condition then data.condition() else data.condition
            data.conditionCss = ko.computed -> return condition.toLowerCase().replace(/\s/g, "-").replace(",-", " ")

        return if not @data.rooms?

        # Indoor average variables.
        temp = 0
        tempCount = 0
        humidity = 0
        humidityCount = 0
        co2 = 0
        co2Count = 0

        # Iterate rooms and update indoor average readings.
        for roomInfo in @data.rooms()
            room = @data[roomInfo.id]

            if room?
                room = room()

                # Get specific readings.
                if room.temperature?
                    temp += parseFloat room.temperature
                    tempCount++
                if room.humidity?
                    humidity += parseFloat room.humidity
                    humidityCount++
                if room.co2?
                    co2 += parseFloat room.co2
                    co2Count++

        tempCount = 1 if tempCount is 0
        humidityCount = 1 if humidityCount is 0
        co2Count = 1 if co2Count is 0

        # Update averages readings and set data.
        if tempCount > 0 and humidityCount > 0
            temp = (temp / tempCount).toFixed 1
            humidity = (humidity / humidityCount).toFixed 0
            co2 = (co2 / co2Count).toFixed 0
            @data.indoorAvg {temperature: temp, humidity: humidity, co2: co2}


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new WeatherView()
