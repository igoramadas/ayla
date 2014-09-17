# SERVER: LIGHTS MANAGER
# -----------------------------------------------------------------------------
# Handles home lights (Philips Hue and RF sockets).
class LightsManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    events = expresser.events
    lodash = expresser.libs.lodash
    logger = expresser.logger
    moment = expresser.libs.moment
    settings = expresser.settings
    sockets = expresser.sockets
    utils = expresser.utils

    title: "Lights"

    # INIT
    # -------------------------------------------------------------------------

    # Init the lights manager.
    init: =>
        @baseInit {hue: []}

    # Start the lights manager and listen to data updates / events.
    start: =>
        events.on "hue.data.hub", @onHueHub
        events.on "hue.light.state", @onHueLightState
        events.on "ninja.data.rf433", @onNinjaDevices

        sockets.listenTo "lightsManager.hue.toggle", @onClientHueToggle
        sockets.listenTo "lightsManager.ninja.toggle", @onClientHNinjaToggle

        @baseStart()

    # Stop the lights manager.
    stop: =>
        events.off "hue.data.hub", @onHueHub
        events.off "hue.light.state", @onHueLightState
        events.off "ninja.data.rf433", @onNinjaDevices

        sockets.stopListening "lightsManager.hue.toggle", @onClientHueToggle
        sockets.stopListening "lightsManager.ninja.toggle", @onClientHNinjaToggle

        @baseStop()

    # HUE
    # -------------------------------------------------------------------------

    # Helper to return a Hue light object.
    createHueLight = (lightId, light) ->
        hex = utils.hslToHex light.state.xy[0], light.state.xy[1], light.state.bri
        state = {on: light.state.on, color: hex}
        return {id: lightId, name: light.name, state: state}

    # Helper to get the HEX colour from Hue lights.
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

    # Update hue lights and groups.
    onHueHub: (data) =>
        @data.hue = {lights: [], groups: []}

        # Iterate groups.
        for groupId, group of data.value.groups
            groupData = {id: groupId, room: group.name, lights: group.lights}
            @data.hue.groups.push groupData

        # Iterate lights.
        for lightId, light of data.value.lights
            light.state.hex = xyBriToHex light.state.xy[0], light.state.xy[1], light.state.bri
            lightData = {id: lightId, name: light.name, state: light.state}
            @data.hue.lights.push lightData

        # Emit updated hue lights and save log.
        @dataUpdated "hue"
        logger.info "LightsManager.onHueHub", @data.hue

    # When Hue light state changes, propagate to clients.
    onHueLightState: (filter, state) =>
        logger.debug "LightsManager.onClientHueToggle", filter, state

        if filter.lightId?
            if lodash.isArray filter.lightId
                arr = filter.lightId
            else
                arr = [filter.lightId]

            # Update all lights by iterating the array of light IDs.
            for id in arr
                light = lodash.find @data.hue.lights, {id: id}
                lodash.assign light.state, state if light?

        # Tell others that hue data was updated.
        @dataUpdated "hue"

    # When a toggle ON/OFF is received from the client.
    onClientHueToggle: (light) =>
        logger.debug "LightsManager.onClientHueToggle", light

        events.emit "hue.setlightstate", {lightId: light.lightId}, {on: light.on}

    # NINJA
    # -------------------------------------------------------------------------

    # Update list of light actuators from Ninja Blocks, by getting all RF433 devices
    # that have "light" on their name.
    onNinjaDevices: (data) =>
        logger.debug "LightsManager.onNinjaDevices", data

        @data.ninja = []

        for id, device of data.value.device.subDevices
            if device.shortName.toLowerCase().indexOf("light") >= 0
                @data.ninja.push {id: id, name: device.shortName, code: device.data}

        # Emit updated ninja lights and save log.
        @dataUpdated "ninja"
        logger.info "LightsManager.onNinjaDevices", @data.ninja

# Singleton implementation.
# -----------------------------------------------------------------------------
LightsManager.getInstance = ->
    @instance = new LightsManager() if not @instance?
    return @instance

module.exports = exports = LightsManager.getInstance()
