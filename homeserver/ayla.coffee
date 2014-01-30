# AYLA
# -----------------------------------------------------------------------------

# Force live environment.
process.env.NODE_ENV = "live"

# Require Expresser.
expresser = require "expresser"
database = expresser.database
settings = expresser.settings

# Required modules.
api = require "./server/api.coffee"
manager = require "./server/manager.coffee"
routes = require "./server/routes.coffee"
security = require "./server/security.coffee"

# Set database helpers.
databaseValidated = -> database.onConnectionValidated = null
database.onConnectionValidated = -> security.init -> api.init -> manager.init -> routes.init -> databaseValidated()

# Init Expresser.
expresser.init()