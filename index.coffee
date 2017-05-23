# AYLA
# -----------------------------------------------------------------------------

# Note on exit.
process.on "exit", (code) -> console.warn "Ayla process exit", code

# Require Expresser.
expresser = require "expresser"
logger = expresser.logger
settings = expresser.settings

# Load private settings.
settings.loadFromJson "settings.private.json"

# Temporary set a global data store on Expresser.
expresser.datastore = {}

# Required modules.
api = require "./server/api.coffee"
commander = require "./server/commander.coffee"
manager = require "./server/manager.coffee"
routes = require "./server/routes.coffee"
appData = require "./server/appdata.coffee"

# Init Expresser.
expresser.init()

# Init app data, then API modules, managers, commander and finally routes.
appData.init -> api.init -> manager.init -> commander.init -> routes.init()

# Automatically update settings when settings.json gets updated.
settings.watch true, -> logger.info "Settings.watch", "Reloaded from disk!"
