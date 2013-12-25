# JARBAS
# -----------------------------------------------------------------------------

# Required modules.
expresser = require "expresser"
api = require "./server/api.coffee"
data = require "./server/data.coffee"
routes = require "./server/routes.coffee"
security = require "./server/security.coffee"

# Init Expresser.
expresser.init()

# Init data cache.
data.init()

# Init security.
security.init()

# Init API.
api.init()

# Set routes.
routes.init()