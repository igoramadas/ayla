# EMAIL
# -----------------------------------------------------------------------------

class Email

    # Required modules.
    expresser = require "expresser"


# Singleton implementation.
# -----------------------------------------------------------------------------
Email.getInstance = ->
    @instance = new Email() if not @instance?
    return @instance

module.exports = exports = Email.getInstance()