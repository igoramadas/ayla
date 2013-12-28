# EMAIL API
# -----------------------------------------------------------------------------
class Email extends (require "./apiBase.coffee")

    expresser = require "expresser"
    logger = expresser.logger
    settings = expresser.settings

    data = require "../data.coffee"
    fs = require "fs"
    imapModule = require "imap"
    lodash = require "lodash"
    mailparser = require "mailparser"
    moment = require "moment"
    util = require "util"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # The IMAP client.
    imap: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Email module and start listening to new message events from the server.
    init: =>
        logger.init "Email.init"

        @imap = new imapModule settings.email.imap
        @start()

    # Start listening to new message events from the server.
    start: =>
        logger.debug "Email.getNewMessages"

        # Bind on ready and open the default inbox.
        @imap.once "ready", =>
            @imap.openBox settings.email.imap.inboxName, false, (err, box) =>
                if err?
                    @logError "Email.start", err

                @fetchNewMessages()
                @imap.on "mail", @fetchNewMessages

        # Connect to the IMAP server.
        @imap.connect()

    # Stop listening to new messages and disconnect.
    stop: =>
        @imap.disconnect()

    # READ MESSAGES
    # -------------------------------------------------------------------------

    # Fetch new messages from the server.
    fetchNewMessages: =>
        @imap.search ["UNSEEN"], (err, results) =>
            if err?
                @logError "Email.fetchNewMessages"

            fetcher = @imap.fetch results, {size: true, struct: true, markSeen: false, bodies: {""}}
            fetcher.on "message", @processMessage
            fetcher.once "error", (err) => @logError "Email.fetchNewMessages", err

    # Process the specified message and load the related Email Action.
    processMessage: (msg, seqno) =>
        parser = new mailparser settings.email.mailparser

        # Parse message body chunks.
        msg.on "body",  (stream, info) -> stream.pipe parser

        # When message ends, check if there's a necessary action, then archive it.
        parser.on "end", (parsedMail) =>
            logger.debug "Email.processMessage", "New message", parsedMail

            # Check if message has a from rule.
            fromRule = lodash.find data.cache.emailRules, {from: parsedMail.from[0].address}
            action = new (require "../emailActions/#{fromRule.action}") if fromRule?

            # Has action? Process it!
            if action?
                logger.debug "Email.processMessage", "Starting action #{fromRule}"
                action.process msg

    # PAGES
    # -------------------------------------------------------------------------

    # Get the Email dashboard data.
    getDashboard: (callback) =>
        @getNewMessages (err, result) =>
            console.warn err, result


# Singleton implementation.
# -----------------------------------------------------------------------------
Email.getInstance = ->
    @instance = new Email() if not @instance?
    return @instance

module.exports = exports = Email.getInstance()