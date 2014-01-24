# AYLA
# -----------------------------------------------------------------------------

# Require Expresser.
expresser = require "expresser"

# Required modules.
api = require "./server/api.coffee"
manager = require "./server/manager.coffee"
routes = require "./server/routes.coffee"
security = require "./server/security.coffee"

# Init Expresser.
expresser.init()
expresser.settings.general.debug = true

# Init the main modules.
security.init => api.init => manager.init()

# Set routes.
routes.init()