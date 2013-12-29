# EMAIL API
# -----------------------------------------------------------------------------
class Email extends (require "./apiBase.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    data = require "../data.coffee"
    fs = require "fs"
    imapModule = require "imap"
    lodash = require "lodash"
    mailparser = require("mailparser").MailParser
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
        logger.debug "Email.init"

        @imap = new imapModule settings.email.imap
        @start()

    # Start listening to new message events from the server.
    start: =>
        logger.info "Email.start"

        @imap.once "ready", =>
            logger.debug "Email.start", "Ready"

            # Open inbox.
            @imap.openBox settings.email.imap.inboxName, false, (err, box) =>
                if err?
                    @logError "Email.start", err
                    @imap.disconnect()
                    return false

                # Inbox open, set running to true and fetch new messages.
                @running = true
                @fetchNewMessages()
                @imap.on "mail", @fetchNewMessages

        # Connect to the IMAP server.
        @imap.connect()

    # Stop listening to new messages and disconnect. Set `running` to false.
    stop: =>
        logger.info "Email.stop"

        @running = false
        @imap.closeBox()
        @imap.end()

    # READ MESSAGES
    # -------------------------------------------------------------------------

    # Fetch new messages from the server.
    fetchNewMessages: =>
        @imap.search ["UNSEEN"], (err, results) =>
            if err?
                @logError "Email.fetchNewMessages", err
            else if not results? or results.length < 1
                logger.debug "Email.fetchNewMessages", "No new messages"
            else
                logger.info "Email.fetchNewMessages", results.length
                fetcher = @imap.fetch results, {size: true, struct: true, markSeen: false, bodies: ""}
                fetcher.on "message", @downloadMessage
                fetcher.once "error", (err) => @logError "Email.fetchNewMessages", err

    # Download the specified message and load the related Email Action.
    downloadMessage: (msg, seqno) =>
        parser = new mailparser settings.email.mailparser
        msgAttributes = {}
        parsedMsg = {}

        # Parse email body.
        parser.on "end", (result) =>
            parsedMsg = result

        # Parse email attachments.
        parser.on "attachment", (att) =>
            try
                output = fs.createWriteStream att.generatedFileName
                att.stream.pipe output
            catch ex
                @logError "Email.downloadMessage.attachment", err

        # Parse message attributes and body chunks.
        msg.on "attributes", (attrs) -> msgAttributes = attrs
        msg.on "body", (stream, info) -> stream.pipe parser

        # On message end check if there's any action to be processed.
        msg.on "end", => lodash.delay @processMessage, settings.email.imap.processDelay, parsedMsg, msgAttributes

    # After message has been downloaded, process it.
    processMessage: (parsedMsg, msgAttributes) =>
        hasFrom = parsedMsg.from[0]?.address?

        # Make sure the `from` is set.
        if not hasFrom
            logger.warn "Email.processMessage", "No 'from' address, skip message."
            return false
        else
            parsedMsg.from = parsedMsg.from[0]
            logger.info "Email.processMessage", msgAttributes.uid, parsedMsg.from.address, parsedMsg.subject

        # Set message attributes.
        parsedMsg.attributes = msgAttributes

        # Check if message has a from rule.
        fromRule = lodash.find data.cache.emailRules, {from: parsedMsg.from.address}
        action = new (require "../emailActions/#{fromRule.action}") if fromRule?

        # Has action? Process it!
        if action?
            action.process parsedMsg, (err, result) =>
                if err?
                    @logError "Email.processMessage.#{action}", msgAttributes.uid, err
                else
                    logger.debug "Email.processMessage.#{action}", "Processed"
                    @archiveMessage parsedMsg
        else
            @archiveMessage parsedMsg

    # Archive a processed message.
    archiveMessage: (parsedMsg) =>
        uid = parsedMsg.attributes.uid

        @imap.move uid, settings.email.imap.archiveName, (err) =>
            if err?
                @logError "Email.archiveMessage", uid, parsedMsg.from.address, parsedMsg.subject, err
            else
                logger.info "Email.archiveMessage", uid, parsedMsg.from.address, parsedMsg.subject

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