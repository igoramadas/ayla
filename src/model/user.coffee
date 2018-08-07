# SERVER: USER MODEL
# -----------------------------------------------------------------------------
class UserModel extends (require "./basemodel.coffee")

    expresser = require "expresser"
    settings = expresser.settings

    # User constructor.
    constructor: (obj, @source) ->
        super obj
        @setData obj

    # Set user data.
    setData: (obj) =>
        data = obj.value or obj

        @name = data.name or @name
        @email = data.email or @email
        @emailMobile = data.emailMobile or @emailMobile
        @computerMac = data.computerMac or @computerMac
        @bluetoothMac = data.bluetoothMac or @bluetoothMac
        @mobileIP = data.mobileIP or @mobileIP
        @location = data.location or @location

        # Set location to Unknown if not set.
        @location = "Unknown" if not @location

        # Set user online or offline
        if data.online is true
            @online = true
        else
            @online = false

        @afterSetData obj

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = UserModel
