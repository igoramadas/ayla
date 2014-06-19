# SERVER: EMAIL MANAGER
# -----------------------------------------------------------------------------
# Handles email messages from users and from the system itself.
class EmailManager extends (require "./basemanager.coffee")

    expresser = require "expresser"
    events = expresser.events
    logger = expresser.logger
    mailer = expresser.mailer
    settings = expresser.settings

    fs = require "fs"
    imapModule = require "imap"
    lodash = expresser.libs.lodash
    mailparser = require("mailparser").MailParser
    moment = expresser.libs.moment
    util = require "util"

    title: "Email"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds all email accounts with IMAP clients.
    accounts: {}

    # The default email and mobile email addresses, taken from
    # the users collections on settings. Set on init.
    defaultTo: null
    defaultToMobile: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Email module and start listening to new message events from the server.
    init: =>
        defaultUser = lodash.find settings.users, {isDefault: true}

        # Set default email if a default user was set, or warn that defaults
        # will be taken from the Expresser Mailer.
        @defaultTo = defaultUser.email if defaultUser?.email?
        @defaultToMobile = defaultUser.emailMobile if defaultUser?.emailMobile?

        # Set default mobile email to same as email if none was specified!
        @defaultToMobile = @defaultTo if not @defaultToMobile?

        @baseInit {processedEmails: []}

    # Start listening to new message events from the server.
    start: =>
        events.on "emailmanager.send", @sendEmail

        # Send email telling Ayla home server has started managing emails.
        if @defaultToMobile?
            mailer.send {to: @defaultToMobile, subject: "Ayla home server started!"}
        else
            logger.warn "Manager.init", "No default user was set, or no mobile email was found."

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
        events.off "emailmanager.send", @sendEmail

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

                    # Try connecting to the inbox again in a few seconds in case it fails.
                    if retry < settings.imap.maxRetry
                        lodash.delay @openBox, settings.imap.retryInterval, account, retry + 1
                    else
                        @logError "EmailManager.openBox", account.id, "Can't connect #{retry} times.", err
                else
                    logger.info "EmailManager.openBox", account.id, "Inbox ready!"

                    # Start fetching unseen messages immediatelly.
                    @fetchNewMessages account
                    account.client.on "mail", => @fetchNewMessages account

        # Handle IMAP errors.
        account.client.on "error", (err) =>
            @logError "EmailManager.openBox.onError", account.id, err

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
        parser = new mailparser {streamAttachments: false}
        msgAttributes = {}
        parsedMsg = {}

        # Parse mail message using mailparser.
        parser.on "end", (result) -> parsedMsg = result

        # Get message attributes and body chunks, and on end proccess the message.
        msg.on "body", (stream, info) -> stream.pipe parser
        msg.once "attributes", (attrs) -> msgAttributes = attrs
        msg.once "end", =>
            parser.end()

            # Delayed processing to make sure parsedMsg is set.
            timedProcess = => @processMessage account, parsedMsg, msgAttributes
            setTimeout timedProcess, 500

    # After message has been downloaded, process it.
    processMessage: (account, parsedMsg, msgAttributes) =>
        hasFrom = parsedMsg.from[0]?.address?

        # Make sure the `from` is set.
        if not hasFrom
            logger.warn "EmailManager.processMessage", account.id, "No valid 'from' address, skip message."
            return false

        # Set parsed message properties.
        parsedMsg.from = parsedMsg.from[0]
        parsedMsg.attributes = msgAttributes

        # Get message actions.
        actions = @getMessageActions account, parsedMsg

        # Has action? Process them!
        if actions.length > 0
            processedEmail = {message: parsedMsg, actions: {}}
            @data.processedEmails.push processedEmail

            for action in actions
                action?.process account, parsedMsg, (err, result) =>
                    processedEmail.actions[action.id] = not err?

                    if err?
                        @logError "EmailManager.processMessage", parsedMsg.from.address, parsedMsg.subject, action.id, err
                    else if result isnt false
                        logger.info "EmailManager.processMessage", "From: #{parsedMsg.from.address}: #{parsedMsg.subject}", action.id
                        @archiveMessage account, parsedMsg unless action.doNotArchive

    # Archive a processed message for the specified account.
    archiveMessage: (account, parsedMsg) =>
        return if parsedMsg.archiving

        if not account.archiveName?
            logger.warn "EmailManager.archiveMessage", account.id, "The specified account has no archive setting defined. Abort!"
            return

        # Set `archibing` flag to prevent duplicate archive routines.
        parsedMsg.archiving = true

        # Move message to the archive box.
        account.client.move parsedMsg.attributes.uid, account.archiveName, (err) =>
            if err?
                @logError "EmailManager.archiveMessage", account.id, parsedMsg.from.address, parsedMsg.subject, err

            @dataUpdated "processedEmails"

    # MESSAGE ACTIONS
    # -------------------------------------------------------------------------

    # Get actions for the specified message based on email rules, or return null if no actions are found.
    getMessageActions: (account, parsedMsg) =>
        actions = []

        # Get matching `from` rules.
        from = lodash.find account.rules, (rule) ->
            return false if not rule.from?
            return false if rule.hasAttachments and parsedMsg.attachments?.length < 1

            arr = if lodash.isArray(rule.from) then rule.from else [rule.from]
            for a in arr
                return true if parsedMsg.from.address.indexOf(a) >= 0
            return false

        # Get matching `subject` rules.
        subject = lodash.find account.rules, (rule) ->
            return false if not rule.subject?
            return false if rule.hasAttachments and parsedMsg.attachments?.length < 1

            arr = if lodash.isArray(rule.subject) then rule.subject else [rule.subject]
            for a in arr
                return true if parsedMsg.subject.indexOf(a) >= 0
            return false

        # Get rules result list by merging results agove.
        rules = lodash.union from, subject
        rules = [] if not rules?

        # Iterate rules and get related action scripts.
        for r in rules
            try
                a = new (require "./emailAction/#{r.action}.coffee")
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
    sendEmail: (options, callback) =>
        if not options.to?
            options.to = if options.mobile then @defaultToMobile else @defaultTo

        logger.info "EmailManager.sendEmail", "From #{options.from} to #{options.to}: #{options.subject}"

        # Send the email using the Expresser Mailer module.
        mailer.send options, (err, result) => callback err, result if callback?


# Singleton implementation.
# -----------------------------------------------------------------------------
EmailManager.getInstance = ->
    @instance = new EmailManager() if not @instance?
    return @instance

module.exports = exports = EmailManager.getInstance()
