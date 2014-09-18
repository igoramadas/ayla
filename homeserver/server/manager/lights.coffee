# SERVER: LIGHTS MANAGER
# -----------------------------------------------------------------------------
# Handles home lights (Philips Hue and RF sockets).
class LightsManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    events = expresser.events
    lightModel = require "../model/light.coffee"
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
        @baseInit {hue: {lights: [], groups: []}}

    # Start the lights manager and listen to data updates / events.
    start: =>
        events.on "hue.data.hub", @onHueHub
        events.on "hue.light.state", @onHueLightState
        events.on "ninja.data.rf433", @onNinjaDevices

        sockets.listenTo "lightsManager.hue.toggle", @onClientHueToggle
        sockets.listenTo "lightsManager.ninja.toggle", @onClientNinjaToggle

        @baseStart()

    # Stop the lights manager.
    stop: =>
        events.off "hue.data.hub", @onHueHub
        events.off "hue.light.state", @onHueLightState
        events.off "ninja.data.rf433", @onNinjaDevices

        sockets.stopListening "lightsManager.hue.toggle", @onClientHueToggle
        sockets.stopListening "lightsManager.ninja.toggle", @onClientNinjaToggle

        @baseStop()

    # HUE
    # -------------------------------------------------------------------------

    # Update hue lights and groups.
    onHueHub: (data) =>
        logger.debug "LightsManager.onHueHub", data

        @data.hue.lights = []
        @data.hue.groups = []

        # Iterate groups.
        for groupId, group of data.value.groups
            obj = {id: groupId, room: group.name, lights: group.lights}
            @data.hue.groups.push obj

        # Iterate lights.
        for lightId, light of data.value.lights
            light.id = lightId
            obj = new lightModel light, "hue"
            @data.hue.lights.push obj

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

        events.emit "hue.setlightstate", {lightId: light.lightId}, {on: light.state}

    # When a toggle ON/OFF is received from the client.
    onClientNinjaToggle: (light) =>
        logger.debug "LightsManager.onClientHueToggle", light

        events.emit "hue.setlightstate", {lightId: light.lightId}, {on: light.state}

    # NINJA
    # -------------------------------------------------------------------------

    # Update list of light actuators from Ninja Blocks, by getting all RF433 devices
    # that have "light" on their name.
    onNinjaDevices: (data) =>
        logger.debug "LightsManager.onNinjaDevices", data

        @data.ninja = []

        for id, device of data.value.device.subDevices
            if device.shortName.toLowerCase().indexOf("light") >= 0
                device.id = id
                obj = new lightModel device, "ninja"
                @data.ninja.push obj

        # Emit updated ninja lights and save log.
        @dataUpdated "ninja"
        logger.info "LightsManager.onNinjaDevices", @data.ninja

# Singleton implementation.
# -----------------------------------------------------------------------------
LightsManager.getInstance = ->
    @instance = new LightsManager() if not @instance?
    return @instance

module.exports = exports = LightsManager.getInstance()
