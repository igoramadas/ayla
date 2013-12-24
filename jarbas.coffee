# JARBAS
# -----------------------------------------------------------------------------

# Required modules.
expresser = require "expresser"
api = require "./server/api.coffee"
data = require "./server/data.coffee"
routes = require "./server/routes.coffee"
security = require "./server/security.coffee"

# Init Expresser.
expresser.init {app: [security.passport.initialize(), security.passport.session()]}

# Init Data.
data.init()

# Init API.
api.init()

# Set routes.
routes.init()