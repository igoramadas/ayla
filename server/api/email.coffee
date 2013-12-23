# EMAIL
# -----------------------------------------------------------------------------
class Email

    expresser = require "expresser"
    logger = expresser.logger

    fs = require "fs"
    imap = require "imap"
    lodash = require "lodash"
    moment = require "moment"

    rules = []

    # INIT
    # -------------------------------------------------------------------------

    # Init the Email module.
    init: =>
        rulesPath = settings.path.data + "emailRules.json"
        rules = require rulesPath





    # READ MESSAGES
    # -------------------------------------------------------------------------

    # Fetch new messages since the specified date (optional, default is last 30 days).
    getNewMessages: (since, callback) =>
        if not since?
            since = moment().subtract "d", settings.email.newMessages.defaultDays

        imap.once "ready", => imap.openBox settings.email.imap.inboxName, false, (err, box) =>
            if err?
                logger.error err
                return callback err

            fetcher = imap.fetch("*", {size: true, struct: true, bodies: {""}})

            # Check each message received from IMAP.
            fetcher.on "message", @processMessage

    # Process the specified message and load the related Email Action.
    processMessage: (msg, sequence) =>
        parsed = {fromAddress: "", fromName: "", body: ""}

        # Parse message body chunks.
        msg.on "body",  (stream, info) ->
            stream.on "data", (chunk) -> parsed.body += chunk.toString settings.general.encoding
            stream.once "end", -> logger.debug "Email.processMessage", "Message body", parsed.body

            # Check if there's a "from" rule for the current message.
            fromRule = lodash.find rules, {from: parsed.fromAddress}
            if fromRule?
                action = new (require "../emailActions/#{fromRule.action}")

            # Has action? Process it!
            if action?
                result = action.process msg

        msg.once "end", =>
            logger.debug "Email.processMessage", "Message closed"




# Singleton implementation.
# -----------------------------------------------------------------------------
Email.getInstance = ->
    @instance = new Email() if not @instance?
    return @instance

module.exports = exports = Email.getInstance()