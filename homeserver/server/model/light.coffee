# SERVER: LIGHT MODEL
# -----------------------------------------------------------------------------
class LightModel extends (require "./basemodel.coffee")

    tinycolor = require "tinycolor2"

    # Light constructor. Default state is off.
    constructor: (obj, @source) ->
        @state = false
        @setData obj

    # Update climate data.
    setData: (obj) =>
        data = obj.value or obj

        @title = data.title or data.shortName or data.name or @title

        # Set state on or off (true or false).
        if data.state?.on?
            @state = data.state?.on
        else if data.on?
            @state = data.on
        else
            @state = data.state or @state

        # This is used for Ninja lights, to define the code to turn on and off.
        @codeOn = data.codeOn if data.codeOn?
        @codeOff = data.codeOff if data.codeOff?

        # Set color depending on the provided info.
        if data.state?.hue? and data.state?.bri?
            hue = (data.state.hue / 65535 * 100).toFixed 2
            sat = (data.state.sat / 255 * 100).toFixed 2
            bri = (data.state.bri / 255 * 100).toFixed 2
            colorObj = tinycolor {h: hue, s: sat, v: bri}
        else if data.colorHex?
            colorObj = tinycolor data.colorHex

        # Color needs update?
        if colorObj?
            hsv = colorObj.toHsv()
            hue = Math.round hsv.h / 360 * 65535
            sat = Math.round hsv.s * 255
            bri = Math.round hsv.v * 255
            @colorHsv = {hue: hue, sat: sat, bri: bri}
            @colorHex = colorObj.toHexString().toUpperCase()

        @afterSetData obj

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = LightModel
