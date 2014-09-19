# SERVER: LIGHT MODEL
# -----------------------------------------------------------------------------
class LightModel extends (require "./basemodel.coffee")

    # Light constructor. Default state is off.
    constructor: (obj, @source) ->
        @state = false
        @setData obj

    # Update climate data.
    setData: (obj) =>
        data = obj.value or obj

        @title = data.title or data.shortName or data.name or @title
        @color = data.color or data.colour or @color

        # Set state on or off (true or false).
        if data.state?.on?
            @state = data.state?.on
        else if data.on?
            @state = data.on

        # This is used for Ninja lights, to define the code to turn on and off.
        @codeOn = data.codeOn if data.codeOn?
        @codeOff = data.codeOff if data.codeOff?

        # Set hue color.
        if data.state?.xy? and data.state?.bri?
            @color = xyBriToHex data.state.xy[0], data.state.xy[1], data.state.bri

        @afterSetData obj

    # Helper to get the HEX colour from xyz lights (Philips Hue for example).
    xyBriToHex = (x, y, bri) ->
        z = 1.0 - x - y
        Y = bri / 255.0
        X = (Y / y) * x
        Z = (Y / y) * z
        r = X * 1.612 - Y * 0.203 - Z * 0.302
        g = -X * 0.509 + Y * 1.412 + Z * 0.066
        b = X * 0.026 - Y * 0.072 + Z * 0.962
        r = (if r <= 0.0031308 then 12.92 * r else (1.0 + 0.055) * Math.pow(r, (1.0 / 2.4)) - 0.055)
        g = (if g <= 0.0031308 then 12.92 * g else (1.0 + 0.055) * Math.pow(g, (1.0 / 2.4)) - 0.055)
        b = (if b <= 0.0031308 then 12.92 * b else (1.0 + 0.055) * Math.pow(b, (1.0 / 2.4)) - 0.055)
        maxValue = Math.max(r, g, b)
        r /= maxValue
        g /= maxValue
        b /= maxValue
        r = r * 255
        r = 255 if r < 0
        g = g * 255
        g = 255 if g < 0
        b = b * 255
        b = 255 if b < 0

        bin = r << 16 | g << 8 | b
        hex = ((h) -> new Array(7 - h.length).join("0") + h) bin.toString(16).toUpperCase()

        return "##{hex}"

# Exports model.
# -----------------------------------------------------------------------------
module.exports = exports = LightModel
