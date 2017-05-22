# SERVER: EMAIL MANAGER
# -----------------------------------------------------------------------------
# Handles email messages from users and from the system itself.
class EmailManager extends (require "./basemanager.coffee")

    expresser = require "expresser"

    appData = require "../appdata.coffee"
    events = expresser.events
    fs = require "fs"
    imapModule = require "imap"
    lodash = expresser.libs.lodash
    logger = expresser.logger
    mailer = expresser.mailer
    mailparser = require("mailparser").MailParser
    moment = expresser.libs.moment
    settings = expresser.settings
    util = require "util"

    title: "Email"
    icon: "fa-envelope-o"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all email accounts with IMAP clients and message IDs.
    accounts: {}
    messageIds: {}

    # The default email and mobile email addresses, taken from
    # the users collections on settings. Set on init.
    defaultTo: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Email module and start listening to new message events from the server.
    init: =>
        defaultUser = lodash.find appData.users, {isDefault: true}

        # Set default email if a default user was set, or warn that defaults
        # will be taken from the Expresser Mailer.
        @defaultTo = defaultUser.email if defaultUser?.email?

        @baseInit {skippedEmails: [], processedEmails: []}

    # Start listening to new message events from the server.
    start: =>
        events.on "EmailManager.send", @send

        # Send email telling Ayla home server has started managing emails.
        if @defaultTo?
            mailer.send {to: @defaultTo, subject: "Ayla home server started!"}
        else
            logger.warn "EmailManager.init", "No default user was set, or no mobile email was found."

        # Create IMAP clients, one for each email account.
        for key, a of settings.emailAccounts
            account = lodash.cloneDeep a
            account.id = key
            account.client = new imapModule account.imap
            @accounts[key] = account
            @openBox account

        @baseStart()

    # Stop listening to new messages and disconnect. Set `running` to false.
    stop: =>
        events.off "EmailManager.send", @send

        # Close IMAP clients.
        for account of @accounts
            try
                account.client.closeBox()
                account.client.end()
            catch ex
                @logError "EmailManager.stop", ex.message, ex.stack

        @baseStop()

    # READ MESSAGES
    # -------------------------------------------------------------------------

    # Open the IMAP email box for the specified account.
    openBox: (account, retry) =>
        if not account?.client?
            logger.warn "EmailManager.openBox", account.id, "The specified account has no valid IMAP client. Please check the email settings."
            return

        # Abort if already connected.
        return if account.client.state is "authenticated"

        retry = 0 if not retry?

        # Once IMAP is ready, open the inbox and start listening to messages.
        account.client.once "ready", =>
            account.client.openBox account.inboxName, false, (err, box) =>
                if err?
                    logger.warn "EmailManager.openBox", account.id, err

                    # Auth failed? Do not try again.
                    if err.textCode is "AUTHORIZATIONFAILED"
                        @logError "EmailManager.openBox", account.id, "Auth failed, please check user and password."
                    # Try connecting to the inbox again in a few seconds in case it fails.
                    else if retry < settings.imap.maxRetry
                        lodash.delay @openBox, settings.imap.retryInterval, account, retry + 1
                    else
                        @logError "EmailManager.openBox", account.id, "Failed to connect #{retry} times. Abort!"
                else
                    logger.info "EmailManager.openBox", account.id, "Inbox ready!"

                    # Start fetching unseen messages immediately
                    @fetchNewMessages account
                    account.client.on "mail", => @fetchNewMessages account

        # Handle IMAP errors. If disconnected because of connection reset, call openBox again.
        account.client.on "error", (err) =>
            @logError "EmailManager.openBox.onError", account.id, err

            if err.code? is "ECONNRESET"
                lodash.delay @openBox, settings.imap.retryInterval, account, 0

        # Connect to the IMAP server.
        account.client.connect()

    # Fetch new unread messages for the specified account.
    fetchNewMessages: (account) =>
        account.client.search ["UNSEEN"], (err, results) =>
            if err?
                @logError "EmailManager.fetchNewMessages", account.id, err
            else if not results? or results.length < 1
                logger.debug "EmailManager.fetchNewMessages", account.id, "No new messages"
            else
                logger.info "EmailManager.fetchNewMessages", account.id, results.length
                fetcher = account.client.fetch results, {size: true, struct: true, markSeen: false, bodies: ""}
                fetcher.on "message", (msg, seqno) => @downloadMessage account, msg, seqno
                fetcher.once "error", (err) => @logError "EmailManager.fetchNewMessages.onError", account.id, err

    # Download the specified message and load the related Email Action.
    downloadMessage: (account, msg, seqno) =>
        parser = new mailparser()
        msgAttributes = {}
        parsedMsg = {}

        # Parse mail message using mailparser.
        parser.on "end", (result) =>
            try
                parsedMsg = result
                @processMessage account, parsedMsg, msgAttributes
            catch ex
                @logError "EmailManager.downloadMessage", ex.message, ex.stack

        # Get message attributes and body chunks, and on end proccess the message.
        msg.on "body", (stream, info) -> stream.pipe parser
        msg.once "attributes", (attrs) -> msgAttributes = attrs
        msg.once "end", -> parser.end()

    # After message has been downloaded, process it.
    processMessage: (account, parsedMsg, msgAttributes) =>
        return if @messageIds[parsedMsg.messageId]
        @messageIds[parsedMsg.messageId] = moment().unix()

        # Make sure the `from` is set.
        hasFrom = parsedMsg.from[0]?.address?

        if not hasFrom
            logger.warn "EmailManager.processMessage", account.id, "No valid 'from' address, skip message."
            return false

        # Set parsed message properties.
        parsedMsg.from = parsedMsg.from[0]
        parsedMsg.attributes = msgAttributes
        parsedMsg.attachments = [] if not parsedMsg.attachments?

        # Get message actions.
        actions = @getMessageActions account, parsedMsg

        # No actions? Add to the skippedMessages list. Message body and attachments
        # will be removed for performance and security reasons.
        if actions.length < 1
            @data.skippedEmails.unshift parsedMsg

            delete parsedMsg.html
            delete a.content for a in parsedMsg.attachments

            if @data.skippedEmails.length >= settings.imap.messagesCacheSize
                @data.skippedEmails.pop()

            @dataUpdated "skippedEmails"

        # Has action? Process them! And append a message to the body.
        else
            logger.debug "EmailManager.processMessage", parsedMsg.from, parsedMsg.subject, "#{actions.length} actions"

            parsedMsg.headers["Ayla-OriginalSender"] = parsedMsg.from
            parsedMsg.headers["Ayla-EmailActions"] = ""

            processedEmail = {message: parsedMsg, actions: []}
            @data.processedEmails.push processedEmail

            for action in actions
                do (action) =>
                    parsedMsg.headers["Ayla-EmailActions"] += action.id + " "

                    action?.process account, parsedMsg, (err, result) =>
                        processedEmail.actions.push {action: action.id, err: err, result: result}

                        if err?
                            @logError "EmailManager.processMessage", parsedMsg.from.address, parsedMsg.subject, action.id, err
                        else if result isnt false
                            logger.info "EmailManager.processMessage", "#{parsedMsg.from.address}: #{parsedMsg.subject}", action.id
                            @archiveMessage account, parsedMsg unless action.doNotArchive

    # Archive a processed message for the specified account.
    archiveMessage: (account, parsedMsg) =>
        return if parsedMsg.archiving

        if not account.archiveName?
            logger.warn "EmailManager.archiveMessage", account.id, "The specified account has no archive setting defined. Abort!"
            return

        # Set `archibing` flag to prevent duplicate archive routines.
        parsedMsg.archiving = true

        # Move message to the archive box. Remove attachments contents for performance reasons.
        account.client.move parsedMsg.attributes.uid, account.archiveName, (err) =>
            account.client.addFlags parsedMsg.attributes.uid, "Seen"

            delete a.content for a in parsedMsg.attachments

            if err?
                @logError "EmailManager.archiveMessage", account.id, parsedMsg.from.address, parsedMsg.subject, err

        @dataUpdated "processedEmails"

    # MESSAGE ACTIONS
    # -------------------------------------------------------------------------

    # Get actions for the specified message based on email rules, or return null if no actions are found.
    getMessageActions: (account, parsedMsg) =>
        actions = []

        # Get matching `from` rules.
        from = lodash.filter account.rules, (rule) ->
            return false if not rule.from?
            return false if rule.hasAttachments and parsedMsg.attachments?.length < 1

            arr = if lodash.isArray(rule.from) then rule.from else [rule.from]
            for a in arr
                return true if parsedMsg.from.address.indexOf(a) >= 0
            return false

        # Get matching `subject` rules.
        subject = lodash.filter account.rules, (rule) ->
            return false if not rule.subject?
            return false if rule.hasAttachments and parsedMsg.attachments?.length < 1

            arr = if lodash.isArray(rule.subject) then rule.subject else [rule.subject]
            for a in arr
                return true if parsedMsg.subject.indexOf(a) >= 0
            return false

        # Get rules result list by merging results agove.
        rules = lodash.uniq(lodash.union from, subject)

        # Iterate rules and get related action scripts.
        for r in rules
            try
                a = new (require "../emailaction/#{r.action}.coffee")
                a.id = r.action
                actions.push a
            catch ex
                @logError "EmailManager.getMessageActions", r.action, ex.message, ex.stack

        # Return actions.
        return actions

    # SEND MESSAGES
    # -------------------------------------------------------------------------

    # Default way to send emails. Called when a module triggers the `emailmanager.send` event.
    # If no `to` is present on the options send to the `defaultTo` specified above, or
    # to the `defaultToMobile` in case `options.mobile` is true.
    send: (options, callback) =>
        options.to = @defaultTo if not options.to?
        logger.info "EmailManager.send", "To #{options.to}: #{options.subject}"

        # Send the email using the Expresser Mailer module.
        mailer.send options, (err, result) => callback err, result if callback?

# Singleton implementation.
# -----------------------------------------------------------------------------
EmailManager.getInstance = ->
    @instance = new EmailManager() if not @instance?
    return @instance

module.exports = exports = EmailManager.getInstance()
