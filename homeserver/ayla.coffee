# AYLA
# -----------------------------------------------------------------------------

# Note on exit.
process.on "exit", (code) -> console.warn "Ayla process exit", code
process.env.AVAHI_COMPAT_NOWARN = 1

# Require Expresser.
expresser = require "expresser"
database = expresser.database
logger = expresser.logger
settings = expresser.settings

# Load private settings.
settings.loadFromJson "settings.private.json"

# Required modules.
api = require "./server/api.coffee"
manager = require "./server/manager.coffee"
routes = require "./server/routes.coffee"

# Init security, api and manager after database has been validated.
database.onConnectionValidated = -> api.init -> manager.init -> routes.init()

# Init Expresser and routes.
expresser.init()

# Automatically update settings when settings.json gets updated.
settings.watch true, -> logger.info "Settings.watch", "Reloaded from disk!"