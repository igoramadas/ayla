# EMAIL API
# -----------------------------------------------------------------------------
class Email extends (require "./baseApi.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

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
        @imap = new imapModule settings.email.imap
        @baseInit()

    # Start listening to new message events from the server.
    start: =>
        @baseStart()
        @openBox()

    # Stop listening to new messages and disconnect. Set `running` to false.
    stop: =>
        @baseStop()
        @imap.closeBox()
        @imap.end()

    # Open the IMAP email box.
    openBox: =>
        if not settings.email?.imap?
            logger.warn "Email.openBox", "IMAP email settings are not defined. Abort!"
            return

        @imap.once "ready", =>
            @imap.openBox settings.email.imap.inboxName, false, (err, box) =>
                if err?
                    @logError "Email.openBox", err
                    @imap.disconnect()
                    return false

                # Inbox open, set running to true and fetch new messages.
                @running = true
                @fetchNewMessages()
                @imap.on "mail", @fetchNewMessages

        # Handle IMAP errors.
        @imap.on "error", (err) =>
            @logError "Email", err

        # Connect to the IMAP server.
        @imap.connect()

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

        # Parse email attachments.
        parser.on "attachment", (att) =>
            try
                output = fs.createWriteStream att.generatedFileName
                att.stream.pipe output
            catch ex
                @logError "Email.downloadMessage.attachment", err

        # Parse message attributes and body chunks.
        parser.on "end", (result) -> parsedMsg = result
        msg.on "body", (stream, info) -> stream.pipe parser
        msg.on "attributes", (attrs) -> msgAttributes = attrs

        # On message end, process parsed message and attributes.
        msg.on "end", =>
            processer = => @processMessage parsedMsg, msgAttributes
            setTimeout processer, settings.email.imap.processDelay

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
        fromRule = lodash.find settings.email.rules, {from: parsedMsg.from.address}
        action = new (require "../emailActions/#{fromRule.action}.coffee") if fromRule?

        # Has action? Process it!
        if action?
            action.process parsedMsg, (err, result) =>
                if err?
                    @logError "Email.processMessage.#{fromRule.action}", msgAttributes.uid, err
                else
                    logger.debug "Email.processMessage.#{fromRule.action}", msgAttributes.uid, "Processed"
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