# GITHUB
# -----------------------------------------------------------------------------

class GitHub

    # Required modules.
    expresser = require "expresser"


# Singleton implementation.
# --------------------------------------------------------------------------
GitHub.getInstance = ->
    @instance = new GitHub() if not @instance?
    return @instance

module.exports = exports = GitHub.getInstance()