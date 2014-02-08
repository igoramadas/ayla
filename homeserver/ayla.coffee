# AYLA
# -----------------------------------------------------------------------------

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
security = require "./server/security.coffee"

# Init security, api and manager after database has been validated.
database.onConnectionValidated = -> security.init -> api.init -> manager.init()

# Init Expresser and routes.
expresser.init()
routes.init()

# Automatically update settings when settings.json gets updated.
settings.watch true, -> logger.info "Settings.watch", "Reloaded from disk!"