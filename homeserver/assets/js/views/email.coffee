# EMAIL VIEW
# --------------------------------------------------------------------------
class EmailView extends ayla.BaseView

    wrapperId: "email"
    socketsName: "emailmanager"
    elements: [".emails"]

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the System Jobs view.
    onReady: =>
        @dataProcessor @data

    # Parse and process data coming from the server.
    dataProcessor: (data) =>
        @data.indoorAvg = ko.observable() if not @data.indoorAvg?

        # Incoming data has condition property? If so, set its css computed value.
        if data.condition?
            condition = if _.isFunction data.condition then data.condition() else data.condition
            data.conditionCss = ko.computed ->
                return condition.toLowerCase().replace(/\s/g, "-")

        # Indoor average variables.
        temp = 0
        tempCount = 0
        humidity = 0
        humidityCount = 0
        co2 = 0
        co2Count = 0

        # Iterate rooms and update indoor average readings.
        for i in ["livingroom", "kitchen", "bedroom", "babyroom"]
            room = @data[i]
            if room?
                room = room()
                if room.temperature?
                    temp += parseFloat room.temperature
                    tempCount++
                if room.humidity?
                    humidity += parseFloat room.humidity
                    humidityCount++
                if room.co2?
                    co2 += parseFloat room.co2
                    co2Count++

        # Update averages readings and set data.
        if tempCount > 0 and humidityCount > 0
            temp = (temp / tempCount).toFixed 1
            humidity = (humidity / humidityCount).toFixed 0
            co2 = (co2 / co2Count).toFixed 0
            @data.indoorAvg {temperature: temp, humidity: humidity, co2: co2}

    # LIGHT CONTROL
    # ----------------------------------------------------------------------

    # Toggle lights om or off based on its current state.
    lightToggle: (e) =>
        console.warn e


# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new EmailView()