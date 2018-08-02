# AYLA
# -----------------------------------------------------------------------------

# Note on exit.
process.on "exit", (code) -> console.warn "Shutting down Ayla", code

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

# Init Expresser.
expresser.init()

# Init app data, then API modules, managers, commander and finally routes.
appData.init -> api.init -> manager.init -> commander.init -> routes.init()

# Automatically update settings when settings.json gets updated.
settings.watch true, -> logger.info "Settings.watch", "Reloaded from disk"
