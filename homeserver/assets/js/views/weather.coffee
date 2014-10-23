# WEATHER VIEW
# --------------------------------------------------------------------------
class WeatherView extends ayla.BaseView

    viewId: "Weather"

    # Init the Weather view.
    onReady: =>
        logger "Loaded Weather View"

        $(".outside .panel").click @toggleChart

    # When user opens another page.
    onDispose: =>
        $(".outside .panel").unbind "click", @toggleChart

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

        # Create chart for forecast.
        if key is "forecastDays"
            @createChart data

        # Set background image for current conditions.
        if key is "forecastCurrent"
            $("#wrapper").removeClass()
            $("#wrapper").addClass data.icon

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
                climate = room.climate

                # Get specific readings.
                if climate.temperature?
                    temp += parseFloat climate.temperature
                    tempCount++
                if climate.humidity?
                    humidity += parseFloat climate.humidity
                    humidityCount++
                if climate.co2?
                    co2 += parseFloat climate.co2
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

    # Create a chart representing the next days forecast.
    createChart: (data) =>
        labels = _.pluck data, "dateString"

        # Set highest temperature dataset.
        dsTemperatureHigh = {
            label: "Temp High"
            fillColor: "rgba(240, 65, 36, 0.3)"
            strokeColor: "rgb(240, 65, 36)"
            pointColor: "rgb(240, 65, 36)"
            pointStrokeColor: "rgb(250, 245, 240)"
            data: _.pluck data, "temperatureHigh"
        }

        # Set lowest temperature dataset.
        dsTemperatureLow = {
            label: "Temp Low"
            fillColor: "rgba(255, 255, 255, 0.9)"
            strokeColor: "rgb(230, 130, 60)"
            pointColor: "rgb(230, 130, 60)"
            pointStrokeColor: "rgb(250, 245, 240)"
            data: _.pluck data, "temperatureLow"
        }

        # Set wind dataset.
        dsWind = {
            label: "Wind"
            fillColor: "Transparent"
            strokeColor: "rgb(160, 170, 160)"
            pointColor: "rgb(160, 170, 160)"
            pointStrokeColor: "rgb(245, 245, 245)"
            data: _.pluck data, "windSpeed"
        }

        # Set precipitaion dataset.
        dsRain = {
            label: "Precp."
            fillColor: "Transparent"
            strokeColor: "rgb(80, 120, 170)"
            pointColor: "rgb(80, 120, 170)"
            pointStrokeColor: "rgb(240, 245, 250)"
            data: _.pluck data, "precpChance"
        }

        # Set line chart options.
        lineOptions = {
            pointDotRadius: 3
        }

        # Resize canvas.
        canvas = $ ".outside canvas"
        cWidth = canvas.parent().innerWidth() - 18
        canvas.prop {width: cWidth}

        # Create chart.
        Chart.defaults.global.scaleFontColor = "rgb(252, 252, 252)"
        chartData = {labels: labels, datasets: [dsTemperatureHigh, dsTemperatureLow, dsWind, dsRain]}
        canvas = canvas.get(0).getContext "2d"
        chart = new Chart(canvas).Line chartData, lineOptions

    # Swap outside view between grid and chart.
    toggleChart: =>
        table = $ ".outside table"
        canvas = $ ".outside canvas"

        if table.is ":visible"
            table.hide()
            canvas.show()
        else
            canvas.hide()
            table.show()

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.weatherView = WeatherView
