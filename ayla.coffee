# AYLA
# -----------------------------------------------------------------------------

# Require Expresser.
expresser = require "expresser"

# Required modules.
api = require "./server/api.coffee"
routes = require "./server/routes.coffee"
security = require "./server/security.coffee"

# Init Expresser.
expresser.init()

# Init the main modules.
api.init()
security.init()

# Set routes.
routes.init()