# MONEY VIEW
# --------------------------------------------------------------------------
class MoneyView extends ayla.BaseView

    wrapperId: "money"

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init the Money view.
    onReady: =>
        @dataProcessor @data

        months = @data.months()

        # Set recent days, usually will be the last 30 days.
        labels = _.pluck months, "shortDate"
        expensesData = []
        incomesData = []

        for m in months
            expensesData.push m.expenses?.amount or 0
            incomesData.push m.incomes?.amount or 0

        # Set expenses dataset.
        dsExpenses = {
            label: "Expenses"
            strokeColor: "#F04124"
            pointColor: "#AA0424"
            data: expensesData
        }

        # Set income dataset.
        dsIncomes = {
            label: "Incomes"
            strokeColor: "#43AC6A"
            pointColor: "#23CC4A"
            data: incomesData
        }

        # Create chart.
        chartData = {labels: labels, datasets: [dsExpenses, dsIncomes]}
        console.warn chartData
        canvas = $("canvas.chart").get(0).getContext "2d"
        chart = new Chart(canvas).Line chartData

    # Parse and process data coming from the server.
    dataProcessor: (key, data) =>
        if not data?
            data = key
            key = null

# BIND VIEW TO WINDOW
# --------------------------------------------------------------------------
window.ayla.currentView = new MoneyView()
