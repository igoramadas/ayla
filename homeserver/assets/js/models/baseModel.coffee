# BASE MODEL
# --------------------------------------------------------------------------
# All models should inherit from this base model class.
class BaseModel

    # The model id.
    id: null

    # MAIN METHODS
    # ----------------------------------------------------------------------

    # Init model and listen to socket events.
    init: (data, eventName) =>
        if data?
            @id = data.id
            @setData data

        # Set model name.
        @modelName = @__proto__.constructor.name.toString()

        # Listen to data updates.
        ayla.sockets.on eventName, @onData if eventName?

    # Stop listening to socket events.
    dispose: =>
        ayla.sockets.off @dataEventName, @onData if @dataEventName?

    # SOCKET SYNC
    # ----------------------------------------------------------------------

    # Fetch model data from the server.
    fetchData: =>
        logger @modelName, @id, "fetchData"

        if window?
            ayla.sockets.emit "#{@modelName.toLowerCase()}:#{@id}:fetch", this

    # Update model data when new values are pushed from the server.
    onData: (data) =>
        if data?
            logger @modelName, @id, "onData"
        else
            logger @modelName, @id, "onData", "Empty!"
            return

        # Parse data as JSON.
        data = JSON.parse data if _.isString data

        # Iterate and update model properties with new data.
        @setData data

        # Model has a `dataReceived`, if so call it.
        @dataReceived data if @dataReceived?

    # Alerts when an error comes from the server.
    onError: (err) =>
        ayla.alerts.error {title: "Could not load #{@modelName} data", message: err.message}


# EXPORTS
# --------------------------------------------------------------------------
window.ayla.baseModel = BaseModel