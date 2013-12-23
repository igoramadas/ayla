# JARBAS IMPLEMENTATION
# -----------------------------------------------------------------------------

# Init expresser.
expresser = require "expresser"
expresser.init()

# Init Jarbas API.
camera = require "api/camera.coffee"
email = require "api/email.coffee"
endomondo = require "api/endomondo.coffee"
fitbit = require "api/fitbit.coffee"
github = require "api/github.coffee"
hue = require "api/hue.coffee"
ninja = require "api/ninja.coffee"
toshl = require "api/toshl.coffee"
withings = require "api/withings.coffee"

# Init sub modules.
camera.init()
email.init()
