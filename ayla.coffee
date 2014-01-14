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
security.init => api.init()

# Set routes.
routes.init()