# AYLA
# -----------------------------------------------------------------------------

# Force live environment.
process.env.NODE_ENV = "live"

# Require Expresser.
expresser = require "expresser"
database = expresser.database
logger = expresser.logger
settings = expresser.settings

# Required modules.
api = require "./server/api.coffee"
manager = require "./server/manager.coffee"
routes = require "./server/routes.coffee"
security = require "./server/security.coffee"

# Init security, api and manager after database has been validated.
databaseValidated = -> database.onConnectionValidated = null
database.onConnectionValidated = -> security.init -> api.init -> manager.init()

# Init Expresser and routes.
expresser.init()
routes.init()

# Automatically update settings when settings.json gets updated.
settings.watch true, -> logger.info "Settings.watch", "Reloaded from disk!"