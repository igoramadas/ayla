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
    sockets = expresser.plugins.sockets
    utils = expresser.utils

    title: "Lights"
    icon: "fa-lightbulb-o"

    # INIT
    # -------------------------------------------------------------------------

    # Init the lights manager.
    init: =>
        @baseInit {hue: {lights: [], groups: []}}

    # Start the lights manager and listen to data updates / events.
    start: =>
        events.on "Hue.data", @onHue
        events.on "Hue.light.state", @onHueLightState

        sockets.listenTo "LightsManager.Hue.color", @onClientHueColor
        sockets.listenTo "LightsManager.Hue.toggle", @onClientHueToggle

        @baseStart()

    # Stop the lights manager.
    stop: =>
        events.off "Hue.data", @onHue
        events.off "Hue.light.state", @onHueLightState

        sockets.stopListening "LightsManager.Hue.color", @onClientHueColor
        sockets.stopListening "LightsManager.Hue.toggle", @onClientHueToggle

        @baseStop()

    # HUE
    # -------------------------------------------------------------------------

    # Update hue hub information.
    onHue: (key, data) =>
        logger.debug "LightsManager.onHueHub", data
        return if key isnt "hub"

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
                    light.setData state
                    logger.info "LightsManager.onHueLightState", light.title, state

        # Tell others that hue data was updated.
        @dataUpdated "hue"

    # When a hue color change received from the client.
    onClientHueColor: (data) =>
        logger.debug "LightsManager.onClientHueColor", data
        light = lodash.find @data.hue.lights, {id: data.lightId}

        # Check if light is valid.
        if not light
            logger.warn "LightsManager.onClientHueColor", data, "Does not exist or has invalid state!"
            return

        # Update light color and emit event to Hue.
        light.setData {colorHex: data.colorHex}

        events.emit "Hue.setLightState", {lightId: light.id}, light.colorHsv, (err, result) =>
            if err?
                err = {message: "Could not updated #{light.title} color.", err: err}
            else
                result = {message: "#{light.title} updated color to #{light.colorHex}.", result: result}

            @emitResultSocket err, result

    # When a toggle ON/OFF is received from the client.
    onClientHueToggle: (data) =>
        logger.debug "LightsManager.onClientHueToggle", data
        light = lodash.find @data.hue.lights, {id: data.lightId}

        # Check if light is valid.
        if not light
            logger.warn "LightsManager.onClientHueToggle", data, "Does not exist or has invalid state!"
            return

        onOrOff = if light.state then "on" else "off"

        # Update light state and emit event to Hue.
        light.setData {state: data.state}

        events.emit "Hue.setLightState", {lightId: light.id}, {on: light.state}, (err, result) =>
            if err?
                err = {message: "Could not toggle hue light #{light.title}.", err: err}
            else
                result = {message: "#{light.title} switched #{onOrOff}", result: result}

            @emitResultSocket err, result

# Singleton implementation.
# -----------------------------------------------------------------------------
LightsManager.getInstance = ->
    @instance = new LightsManager() if not @instance?
    return @instance

module.exports = exports = LightsManager.getInstance()
