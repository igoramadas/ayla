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

    # The IMAP client.
    imap: null

    # The default email and mobile email addresses, taken from
    # the users collections on settings. Set on init.
    defaultTo: null
    defaultToMobile: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the Email module and start listening to new message events from the server.
    init: =>
        @imap = new imapModule settings.email.imap

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

        @openBox()
        @baseStart()

    # Stop listening to new messages and disconnect. Set `running` to false.
    stop: =>
        @baseStop()
        @imap.closeBox()
        @imap.end()

    # READ MESSAGES
    # -------------------------------------------------------------------------

    # Open the IMAP email box.
    openBox: =>
        if not settings.email?.imap?
            logger.warn "Email.openBox", "IMAP email settings are not defined. Abort!"
            return

        # Once IMAP is ready, open the inbox and start listening to messages.
        @imap.once "ready", =>
            @imap.openBox settings.email.imap.inboxName, false, (err, box) =>
                if err?
                    @logError "Email.openBox", err
                    @imap.disconnect()
                    @running = false
                else
                    @running = true
                    @fetchNewMessages()
                    @imap.on "mail", @fetchNewMessages

        # Handle IMAP errors.
        @imap.on "error", (err) =>
            @logError "Email", err

        # Connect to the IMAP server.
        @imap.connect()

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
                @logError "Email.downloadMessage.attachment", ex

        # Parse message attributes and body chunks.
        parser.on "end", (result) -> parsedMsg = result
        msg.on "body", (stream, info) -> stream.pipe parser
        msg.on "attributes", (attrs) -> msgAttributes = attrs

        # On message end, process parsed message and attributes.
        msg.on "end", => lodash.delay  @processMessage, settings.email.imap.processDelay, parsedMsg, msgAttributes

    # After message has been downloaded, process it.
    processMessage: (parsedMsg, msgAttributes) =>
        hasFrom = parsedMsg.from[0]?.address?

        # Make sure the `from` is set.
        if not hasFrom
            logger.warn "Email.processMessage", "No valid 'from' address, skip message."
            return false

        # Set parsed message properties.
        parsedMsg.from = parsedMsg.from[0]
        parsedMsg.attributes = msgAttributes
        logger.info "Email.processMessage", msgAttributes.uid, parsedMsg.from.address, parsedMsg.subject

        # Get message actions.
        actions = @getMessageActions parsedMsg

        # Has action? Process them!
        if actions.length > 0
            for action in actions
                action?.process parsedMsg, (err, result) =>
                    if err?
                        @logError "Email.processMessage", msgAttributes.uid, action.id, err
                    else
                        logger.info "Email.processMessage", msgAttributes.uid, action.id, result

            # Archive messages if they had macthing actions.
            @archiveMessage parsedMsg

    # Archive a processed message.
    archiveMessage: (parsedMsg) =>
        if not settings.email.imap?.archiveName?
            logger.warn "Email.archiveMessage", "The IMAP archive setting is not defined. Abort!"
            return

        # Move message to the archive box.
        @imap.move parsedMsg.attributes.uid, settings.email.imap.archiveName, (err) =>
            if err?
                @logError "Email.archiveMessage", parsedMsg.attributes.uid
            else
                logger.debug "Email.archiveMessage", parsedMsg.attributes.uid

    # SEND MESSAGES
    # -------------------------------------------------------------------------

    # Default way to send emails. Called when a module triggers the `emailmanager.send` event.
    # If no `to` is present on the options send to the `defaultTo` specified above, or
    # to the `defaultToMobile` in case `options.mobile` is true.
    onSend: (options) =>
        if not options.to?
            options.to = if options.mobile then @defaultToMobile else @defaultTo

        # Send the email using the Expresser Mailer module.
        mailer.send options, (err, result) => callback err, result if callback?

    # MESSAGE ACTIONS
    # -------------------------------------------------------------------------

    # Get actions for the specified message based on email rules, or return null if no actions are found.
    getMessageActions: (parsedMsg) =>
        actions = []

        # Get and merge all matching rules.
        from = lodash.find settings.email.rules, (rule) -> return parsedMsg.from.address.indexOf(rule.from) >=0
        subject = lodash.find settings.email.rules, (rule) -> return parsedMsg.subject.indexOf(rule.subject) >=0
        rules = lodash.merge from, subject

        # Iterate rules and get related action scripts.
        for r in rules
            a = new (require "../emailActions/#{r.id}.coffee")
            a.id = r.id
            actions.push a

        # Return actions.
        return actions

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