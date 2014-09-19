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

        # Sort collections.
        @data.hue.groups = lodash.sortBy @data.hue.groups, "room"
        @data.hue.lights = lodash.sortBy @data.hue.lights, "title"
        logger.debug "LightsManager.onHueHub", @data.hue

        # Emit updated hue lights and save log.
        @dataUpdated "hue"

    # When Hue light state changes, propagate to clients.
    onHueLightState: (filter, state) =>
        logger.debug "LightsManager.onHueLightState", filter, state

        if filter.lightId?
            if lodash.isArray filter.lightId
                arr = filter.lightId
            else
                arr = [filter.lightId]

            # Update all lights by iterating the array of light IDs.
            for id in arr
                light = lodash.find @data.hue.lights, {id: id}

                if light?
                    lodash.assign light.state, state
                    logger.debug "LightsManager.onHueLightState", light, "Changed state", state

        # Tell others that hue data was updated.
        @dataUpdated "hue"

    # When a toggle ON/OFF is received from the client., filtered by light ID.
    onClientHueToggle: (light) =>
        logger.debug "LightsManager.onClientHueToggle", light

        events.emit "hue.setLightState", {lightId: light.lightId}, {on: light.state}

    # When a toggle ON/OFF is received from the client, filtered by title.
    onClientNinjaToggle: (light) =>
        logger.debug "LightsManager.onClientHueToggle", light

        events.emit "ninja.actuate433", light

    # NINJA
    # -------------------------------------------------------------------------

    # Update list of light actuators from Ninja Blocks, by getting all RF433 devices
    # that have "light" on their name.
    onNinjaDevices: (data) =>
        logger.debug "LightsManager.onNinjaDevices", data

        @data.ninja = []
        lights = {}

        # Iterated filtered light list to create the specific light models.
        # It merges devices containing same title with On and Off.
        for id, device of data.value.device.subDevices
            if device.shortName.toLowerCase().indexOf("light") >= 0
                lightTitle = device.shortName.replace(" On", "").replace(" Off", "")
                device.id = id
                device.title = lightTitle

                if not lights[lightTitle]?
                    lights[lightTitle] = new lightModel device, "ninja"
                else
                    lights[lightTitle].setData device

                # Here's where the action happens. Instead of creating one light for Off
                # and another for On, we merge them and set the codeOn and codeOff properties.
                if device.shortName.indexOf(" On") > 0
                    lights[lightTitle].codeOn = id
                else if device.shortName.indexOf(" Off") > 0
                    lights[lightTitle].codeOff = id

        # Push created light models to the ninja light collection.
        @data.ninja.push light for title, light of lights
        logger.debug "LightsManager.onNinjaDevices", @data.ninja

        # Emit updated ninja lights and save log.
        @dataUpdated "ninja"

# Singleton implementation.
# -----------------------------------------------------------------------------
LightsManager.getInstance = ->
    @instance = new LightsManager() if not @instance?
    return @instance

module.exports = exports = LightsManager.getInstance()
