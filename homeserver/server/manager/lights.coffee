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

        @baseStart()

    # Stop the lights manager.
    stop: =>
        events.off "hue.data.hub", @onHueHub
        events.off "ninja.data.rf433", @onNinjaDevices

        @baseStop()

    # LIGHTS
    # -------------------------------------------------------------------------

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
                lightData = data.lights[lightId]
                hex = utils.hslToHex lightData.state.xy[0], lightData.state.xy[1], lightData.state.bri
                state = {on: lightData.state.on, color: hex}
                groupData.lights.push {id: lightId, name: lightData.name, state: state}
                lightsWithGroups.push lightId.toString()

        # Process light HEX colours and add lights with no groups to the "Other" group.
        for lightId, light of data.lights
            light.state.hex = utils.hslToHex light.state.hue, light.state.bri, light.state.sat

            if not lodash.contains lightsWithGroups, lightId.toString()
                otherLights.push {id: lightId, name: lightData.name, state: state}

        @data.hue.push {id: "other", room: "Other", lights: otherLights}

        # Emit updated hue lights and save log.
        @dataUpdated "hue"
        logger.info "LightsManager.onHueHub", @data.hue

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

# Singleton implementation.
# -----------------------------------------------------------------------------
LightsManager.getInstance = ->
    @instance = new LightsManager() if not @instance?
    return @instance

module.exports = exports = LightsManager.getInstance()
