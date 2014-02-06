# SERVER: EMAIL MANAGER
# -----------------------------------------------------------------------------
# Handles email messages to execute custom actions.
class EmailManager extends (require "./baseManager.coffee")

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
        # Get default user to set email and mobile email.
        defaultUser = lodash.find settings.users, {isDefault: true}

        # Set default email if a default user was set, or warn that defaults
        # will be taken from the Expresser Mailer.
        @defaultTo = defaultUser.email if defaultUser?.email?
        @defaultToMobile = defaultUser.emailMobile if defaultUser?.emailMobile?

        @baseInit()

    # Start listening to new message events from the server.
    start: =>
        events.on "emailmanager.send", @sendEmail
        events.on "fitbit.sleep.missing", @onFitbitSleepMissing

        # Send email telling Ayla home server has started managing emails.
        if @defaultToMobile?
            mailer.send {to: @defaultToMobile, subject: "Ayla home server started!", body: "Hi there, sir."}
        else
            logger.warn "Manager.init", "No default user was set, or no mobile email was found."

        # Create IMAP clients, one for each email account.
        for key, email of settings.emailAccounts
            e = email
            e.client = new imapModule e.imap
            @accounts[key] = e
            @openBox @accounts[key]

        @baseStart()

    # Stop listening to new messages and disconnect. Set `running` to false.
    stop: =>
        for i of @accounts
            i.closeBox()
            i.end()

        @baseStop()

    # READ MESSAGES
    # -------------------------------------------------------------------------

    # Open the IMAP email box for the specified account.
    openBox: (account) =>
        if not account?.client?
            logger.warn "Email.openBox", "The specified account has no valid IMAP client. Abort!"
            return

        # Once IMAP is ready, open the inbox and start listening to messages.
        account.client.once "ready", =>
            account.client.openBox account.inboxName, false, (err, box) =>
                if err?
                    @logError "Email.openBox", account.imap.user, err
                    account.client.disconnect()
                else
                    @fetchNewMessages account
                    account.client.on "mail", => @fetchNewMessages account

        # Handle IMAP errors.
        account.client.on "error", (err) =>
            @logError "Email.openBox", account.imap.user, err

        # Connect to the IMAP server.
        account.client.connect()

    # Fetch new unread messages for the specified account.
    fetchNewMessages: (account) =>
        account.client.search ["UNSEEN"], (err, results) =>
            if err?
                @logError "Email.fetchNewMessages", account.imap.user, err
            else if not results? or results.length < 1
                logger.debug "Email.fetchNewMessages", account.imap.user, "No new messages"
            else
                logger.info "Email.fetchNewMessages", account.imap.user, results.length
                fetcher = account.client.fetch results, {size: true, struct: true, markSeen: false, bodies: ""}
                fetcher.on "message", (msg, seqno) => @downloadMessage account, msg, seqno
                fetcher.once "error", (err) => @logError "Email.fetchNewMessages", account.imap.user, err

    # Download the specified message and load the related Email Action.
    downloadMessage: (account, msg, seqno) =>
        parser = new mailparser {streamAttachments: true}
        msgAttributes = {}
        parsedMsg = {}

        # Parse email attachments.
        parser.on "attachment", (att) =>
            try
                output = fs.createWriteStream att.generatedFileName
                att.stream.pipe output
            catch ex
                @logError "Email.downloadMessage.attachment", seqno, ex

        # Parse message attributes and body chunks.
        parser.on "end", (result) -> parsedMsg = result
        msg.on "body", (stream, info) -> stream.pipe parser
        msg.on "attributes", (attrs) -> msgAttributes = attrs

        # On message end, process parsed message and attributes.
        msg.on "end", => lodash.delay  @processMessage, 500, account, parsedMsg, msgAttributes

    # After message has been downloaded, process it.
    processMessage: (account, parsedMsg, msgAttributes) =>
        hasFrom = parsedMsg.from[0]?.address?

        # Make sure the `from` is set.
        if not hasFrom
            logger.warn "Email.processMessage", account.imap.user, "No valid 'from' address, skip message."
            return false

        # Set parsed message properties.
        parsedMsg.from = parsedMsg.from[0]
        parsedMsg.attributes = msgAttributes
        logger.info "Email.processMessage", account.imap.user, msgAttributes.uid, parsedMsg.from.address, parsedMsg.subject

        # Get message actions.
        actions = @getMessageActions account, parsedMsg

        # Has action? Process them!
        if actions.length > 0
            for action in actions
                action?.process parsedMsg, (err, result) =>
                    if err?
                        @logError "Email.processMessage", msgAttributes.uid, action.id, err
                    else
                        # All good? Archive messages unless action has the `doNotArchive` flag.
                        @archiveMessage account, parsedMsg unless action.doNotArchive
                        logger.info "Email.processMessage", msgAttributes.uid, action.id, result

    # Archive a processed message for the specified account.
    archiveMessage: (account, parsedMsg) =>
        return if parsedMsg.archiving

        if not account.archiveName?
            logger.warn "Email.archiveMessage", account.imap.user, "The specified account has no archive setting defined. Abort!"
            return

        # Set `archibing` flag to prevent duplicate archive routines.
        parsedMsg.archiving = true

        # Move message to the archive box.
        account.client.move parsedMsg.attributes.uid, account.archiveName, (err) =>
            if err?
                @logError "Email.archiveMessage", account.imap.user, parsedMsg.attributes.uid
            else
                logger.debug "Email.archiveMessage", account.imap.user, parsedMsg.attributes.uid

    # MESSAGE ACTIONS
    # -------------------------------------------------------------------------

    # Get actions for the specified message based on email rules, or return null if no actions are found.
    getMessageActions: (account, parsedMsg) =>
        actions = []

        # Get and merge all matching rules.
        from = lodash.find account.rules, (rule) -> return parsedMsg.from.address.indexOf(rule.from) >=0
        subject = lodash.find account.rules, (rule) -> return parsedMsg.subject.indexOf(rule.subject) >=0
        rules = lodash.merge from, subject

        # Iterate rules and get related action scripts.
        for r in rules
            a = new (require "../emailActions/#{r.action}.coffee")
            a.id = r.id
            actions.push a

        # Return actions.
        return actions

    # SEND MESSAGES
    # -------------------------------------------------------------------------

    # Default way to send emails. Called when a module triggers the `emailmanager.send` event.
    # If no `to` is present on the options send to the `defaultTo` specified above, or
    # to the `defaultToMobile` in case `options.mobile` is true.
    sendEmail: (options) =>
        if not options.to?
            options.to = if options.mobile then @defaultToMobile else @defaultTo

        # Send the email using the Expresser Mailer module.
        mailer.send options, (err, result) => callback err, result if callback?

    # FITBIT MESSAGES
    # -------------------------------------------------------------------------

    # Notify user of missing sleep data by email.
    onFitbitSleepMissing: (data) =>
        msgOptions = {to: settings.email.toDefault, subject: "Missing sleep data for #{date}", keywords: {}}
        msgOptions.template = "fitbitMissingSleep"
        msgOptions.keywords.date = date
        msgOptions.keywords.dateUrl = date.replace "-", "/"

        # Send the email.
        mailer.send msgOptions, (errM, resultM) =>
            if errM?
                @logError "Fitbit.jobCheckMissingData", "mailer.send", errM
                return false
            else
                logger.info "Fitbit.jobCheckMissingData", "Notified of missing sleep on #{date}."



# Singleton implementation.
# -----------------------------------------------------------------------------
EmailManager.getInstance = ->
    @instance = new EmailManager() if not @instance?
    return @instance

module.exports = exports = EmailManager.getInstance()