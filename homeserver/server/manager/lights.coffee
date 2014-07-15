# SERVER: LIGHTS MANAGER
# -----------------------------------------------------------------------------
# Handles home lights (Philips Hue and RF sockets).
class LightsManager extends (require "./basemanager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings
    sockets = expresser.sockets
    utils = expresser.utils

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment

    title: "Lights"

    # INIT
    # -------------------------------------------------------------------------

    # Init the lights manager.
    init: =>
        @baseInit {hue: []}

    # Start the lights manager and listen to data updates / events.
    start: =>
        events.on "hue.data.hub", @onHueHub
        events.on "ninja.data.rf433", @onNinjaDevices

        sockets.listenTo "lightsmanager.hue.toggle", @onClientHueToggle
        sockets.listenTo "lightsmanager.ninja.toggle", @onClientHNinjaToggle

        @baseStart()

    # Stop the lights manager.
    stop: =>
        events.off "hue.data.hub", @onHueHub
        events.off "ninja.data.rf433", @onNinjaDevices

        sockets.stopListening "lightsmanager.hue.toggle", @onClientHueToggle
        sockets.stopListening "lightsmanager.ninja.toggle", @onClientHNinjaToggle

        @baseStop()

    # HUE
    # -------------------------------------------------------------------------

    # Helper to return a Hue light object.
    createHueLight = (lightId, light) ->
        hex = utils.hslToHex light.state.xy[0], light.state.xy[1], light.state.bri
        state = {on: light.state.on, color: hex}
        return {id: lightId, name: light.name, state: state}

    # Update hue lights and groups.
    onHueHub: (data) =>
        @data.hue = []

        # This will hold a list of all lights that have groups associated
        # and lights with no groups go to otherLights.
        lightsWithGroups = []
        otherLights = []

        # Iterate groups.
        for groupId, group of data.groups
            groupData = {id: groupId, room: group.name, lights: []}
            @data.hue.push groupData

            # Iterate group lights.
            for lightId in group.lights
                groupData.lights.push createHueLight lightId, data.lights[lightId]
                lightsWithGroups.push lightId.toString()

        # Add lights with no groups to the "Other" group.
        for lightId, light of data.lights
            if not lodash.contains lightsWithGroups, lightId.toString()
                otherLights.push createHueLight lightId, light

        @data.hue.push {id: "other", room: "Other", lights: otherLights}

        # Emit updated hue lights and save log.
        @dataUpdated "hue"
        logger.info "LightsManager.onHueHub", @data.hue

    # When a toggle ON/OFF is received from the client.
    onClientHueToggle: (light) =>
        logger.info "LightsManager.onClientHueToggle", light

        events.emit "hue.setlightstate", {lightId: light.lightId}, {on: light.on}

    # NINJA
    # -------------------------------------------------------------------------

    # Update list of light actuators from Ninja Blocks, by getting all RF433 devices
    # that have "light" on their name.
    onNinjaDevices: (data) =>
        @data.ninja = []

        for id, device of data.device.subDevices
            if device.shortName.toLowerCase().indexOf("light") >= 0
                @data.ninja.push {id: id, name: device.shortName, code: device.data}

        # Emit updated ninja lights and save log.
        @dataUpdated "ninja"
        logger.info "LightsManager.onNinjaDevices", @data.ninja

    # When a toggle ON/OFF is received from the client for a Ninja power socket.
    onClientNinjaToggle: (light) =>
        logger.info "LightsManager.onClientNinjaToggle", light

        events.emit "ninja.actuate433", {id: light.lightId}

# Singleton implementation.
# -----------------------------------------------------------------------------
LightsManager.getInstance = ->
    @instance = new LightsManager() if not @instance?
    return @instance

module.exports = exports = LightsManager.getInstance()
