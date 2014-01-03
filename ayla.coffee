# AYLA
# -----------------------------------------------------------------------------

# Require Expresser.
expresser = require "expresser"

# Required modules.
api = require "./server/api.coffee"
data = require "./server/data.coffee"
network = require "./server/network.coffee"
routes = require "./server/routes.coffee"
security = require "./server/security.coffee"

# Init Expresser.
expresser.init()

# Init the main modules.
data.init()
network.init()
security.init()

# Init API and set routes.
api.init()
routes.init()