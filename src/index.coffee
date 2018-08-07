# AYLA
# -----------------------------------------------------------------------------

# Note on exit.
process.on "exit", (code) -> console.warn "Shutting down Ayla...", "Code #{code}"

# Require Expresser.
expresser = require "expresser"
logger = expresser.logger
settings = expresser.settings

# Load private settings.
settings.loadFromJson "settings.private.json"

# Temporary set a global data store on Expresser.
expresser.datastore = {}

# Required modules.
api = require "./api.coffee"
commander = require "./commander.coffee"
manager = require "./manager.coffee"
routes = require "./routes.coffee"
appData = require "./appdata.coffee"

# Init server, app data, then API modules, managers, commander and finally routes.
startup = ->
    try
        expresser.init()
        await appData.init()
        await api.init()
        await manager.init()
        await commander.init()
        await routes.init()
    catch ex
        logger.error "Can't start the Ayla server!"
        return process.exit()

    return async

startup()

# Automatically update settings when settings.json gets updated.
settings.watch -> logger.info "Settings.watch", "Reloaded from disk"
