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

        @baseStart()

    # Stop the lights manager.
    stop: =>
        events.off "hue.data.hub", @onHueHub

        @baseStop()

    # LIGHTS
    # -------------------------------------------------------------------------

    # Update hue lights and groups.
    onHueHub: (data) =>
        @data.hue = []

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

        # Emit updated lights and save log.
        @dataUpdated "hue"
        logger.info "LightsManager.onHueHub", @data.hue


# Singleton implementation.
# -----------------------------------------------------------------------------
LightsManager.getInstance = ->
    @instance = new LightsManager() if not @instance?
    return @instance

module.exports = exports = LightsManager.getInstance()