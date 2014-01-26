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

# Init the main modules.
security.init -> api.init -> manager.init ->
    routes.init()
    expresser.mailer.send {to: settings.email.toMobile, subject: "Ayla home server started!", body: "Hi there, sir."}