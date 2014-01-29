# AYLA
# -----------------------------------------------------------------------------

# Force live environment.
process.env.NODE_ENV = "live"

# Require Expresser.
expresser = require "expresser"
settings = expresser.settings

# Required modules.
api = require "./server/api.coffee"
manager = require "./server/manager.coffee"
routes = require "./server/routes.coffee"
security = require "./server/security.coffee"

# Init Expresser.
expresser.init()

# Init the main modules.
security.init -> api.init -> manager.init -> routes.init()