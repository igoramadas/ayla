# SERVER: OAUTH
# -----------------------------------------------------------------------------
# Controls authentication using OAuth1 or OAuth2.
class OAuth

    expresser = require "expresser"
    database = expresser.database
    events = expresser.events
    logger = expresser.logger
    settings = expresser.settings

    lodash = expresser.libs.lodash
    moment = expresser.libs.moment
    oauthModule = require "oauth"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds a copy of users and tokens.
    data: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the OAuth module and refresh auth tokens from the database.
    constructor: (@service) ->
        logger.debug "OAuth", "New for #{@service}"

    # AUTH SYNC
    # -------------------------------------------------------------------------

    # Get most recent auth tokens from the database and update the `oauth` DB collection.
    # Callback (err, result) is optional.
    loadTokens: (callback) =>
        database.get "oauth", {"service": @service, "active": true}, (err, result) =>
            if err?
                logger.critical "OAuth.loadTokens", err
                callback err, false if callback?
            else
                logger.debug "OAuth.loadTokens", result
                for t in result
                    @client = getClient @service
                    @data[t.user] = t
                if callback?
                    callback null, true

    # Remove old auth tokens from the database.
    cleanTokens: (callback) =>
        minTimestamp = moment().unix() - (settings.security.maxAuthTokenAgeDays * 24 * 60 * 60)

        database.del "oauth", {timestamp: {$lt: minTimestamp}}, (err, result) =>
            if err?
                logger.error "OAuth.cleanTokens", "Timestamp #{minTimestamp}", err
            else
                logger.debug "OAuth.cleanTokens", "Timestamp #{minTimestamp}", "OK"
            if callback?
                callback err, result

    # Save the specified auth token to the database. Please note that tokens must be associated with a specific user.
    # If no uyser is set, use the default user (flagged with isDefault=true on the settings file).
    saveToken: (params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get current time and set data.
        now = moment().unix()
        data = lodash.defaults params, {service: @service, active: true, timestamp: now}

        # Add extra parameters, if any.
        data.timestamp = params.oauth_timestamp if params.oauth_timestamp?
        data.userId = params.encoded_user_id if params.encoded_user_id?
        data.userId = params.userid if params.userid?

        # Make sure user is associated, or assume default user.
        if not @data.user? or @data.user is ""
            @data.user = lodash.findKey settings.users, {isDefault: true}

        # Set local oauth cache.
        @data = data

        # Update oauth collection and set related tokens `active` to false.
        database.set "oauth", {active: false}, {patch: true, upsert: false, filter: {service: @service}}, (err, result) =>
            if err?
                logger.error "OAuth.saveToken", @service, "Set active=false", err
            else
                logger.debug "OAuth.saveToken", @service, "Set active=false", "OK"

            # Save to database.
            database.set "oauth", data, (err, result) =>
                if err?
                    logger.error "OAuth.saveToken", @service, data, err
                else
                    logger.debug "OAuth.saveToken", @service, data, "OK"
                if callback?
                    callback err, result

    # PROCESSING AND REQUESTING
    # -------------------------------------------------------------------------

    # Helper to the an OAuth client for a particular service.
    getClient = (service) ->
        callbackUrl = settings.general.appUrl + service + "/auth/callback"
        headers = {"Accept": "*/*", "Connection": "close", "User-Agent": "Ayla #{packageJson.version}"}
        version = settings[service].api.oauthVersion

        if version is "2.0"
            return new oauthModule.OAuth2(
                settings[service].api.clientId,
                settings[service].api.secret,
                settings[service].api.oauthUrl,
                settings[service].api.oauthPathAuthorize,
                settings[service].api.oauthPathToken,
                headers)
        else
            return new oauthModule.OAuth(
                settings[service].api.oauthUrl + "request_token",
                settings[service].api.oauthUrl + "access_token",
                settings[service].api.clientId,
                settings[service].api.secret,
                version,
                callbackUrl,
                "HMAC-SHA1",
                null,
                headers)

    # Get an OAuth protected resource.
    get: (reqUrl, callback) =>
        if settings[@service].api.oauthVersion is "2.0"
            @client.get reqUrl, @data.accessToken, callback
        else
            @client.get reqUrl, @data.token, @data.tokenSecret, callback

    # Try getting OAuth data for a particular request / response.
    process: (options, req, res) =>
        if not res? and req?
            res = req
            req = options
            options = null

        # Check if OAuth client was already created, if not then create one.
        if not @client?
            @client = getClient @service
            @data = {}

        # Check if request has token on querystring.
        qs = url.parse(req.url, true).query if req?

        # Helper function to get the request token using OAUth 1.x.
        getRequestToken1 = (err, oauth_token, oauth_token_secret, oauth_authorize_url, additionalParameters) =>
            if err?
                logger.error "OAuth.process", "getRequestToken1", @service, err
                return

            logger.info "OAuth.process", "getRequestToken1", @service, oauth_token

            # Set token secret cache and redirect to authorization URL.
            @data.tokenSecret = oauth_token_secret
            res?.redirect "#{settings[@service].api.oauthUrl}authorize?oauth_token=#{oauth_token}"

        # Helper function to get the access token using OAUth 1.x.
        getAccessToken1 = (err, oauth_token, oauth_token_secret, additionalParameters) =>
            if err?
                logger.error "OAuth.process", "getAccessToken1", @service, err
                return

            logger.info "OAuth.process", "getAccessToken1", @service, oauth_token

            # Save oauth details to DB and redirect user to service page.
            oauthData = lodash.defaults {token: oauth_token, tokenSecret: oauth_token_secret}, additionalParameters
            @saveToken oauthData
            res?.redirect "/#{@service}"

        # Helper function to get the access token using OAUth 2.x.
        getAccessToken2 = (err, oauth_access_token, oauth_refresh_token, results) =>
            if err?
                logger.error "OAuth.process", "getAccessToken2", @service, err
                return

            logger.info "OAuth.process", "getAccessToken2", @service, oauth_access_token

            # Schedule token to be refreshed automatically with 10% of the expiry time left.
            expires = results?.expires_in or results?.expires or 43200
            lodash.delay @refresh, expires * 900, @service

            # Save oauth details to DB and redirect user to service page.
            oauthData = {accessToken: oauth_access_token, refreshToken: oauth_refresh_token, expires: moment().add("s", expires)}
            @saveToken oauthData
            res?.redirect "/#{@service}"

        # Set correct request handler based on OAUth parameters and query tokens.
        if settings[@service].api.oauthVersion is "2.0"

            # Use cliend credentials (password) or authorization code?
            if settings[@service].api.username?
                opts = {"grant_type": "password", username: settings[@service].api.username, password: settings[@service].api.password}
            else
                opts = {"grant_type": "authorization_code"}

            if settings[service].api.oauthResponseType?
                opts["response_type"] = settings[@service].api.oauthResponseType

            qCode = qs?.code
            @client.getOAuthAccessToken qCode, opts, getAccessToken2

            # Getting an OAuth1 access token?
        else if qs?.oauth_token?
            @client.getOAuthAccessToken qs.oauth_token, @data.tokenSecret, qs.oauth_verifier, getAccessToken1
        else
            @client.getOAuthRequestToken {}, getRequestToken1

    # Helper to refresh an OAuth2 token.
    refresh: =>
        if not @client?
            logger.warn "OAuth.refresh", @service, "OAuth client not ready. Abort refresh!"
            return

        # Abort if token is already being refreshed.
        return if @refreshing

        # Get oauth object and refresh token and set grant type to refresh_token.
        @refreshing = true
        refreshToken = @data.refreshToken
        opts = {"grant_type": "refresh_token"}

        if settings[@service].api.oauthResponseType?
            opts["response_type"] = settings[@service].api.oauthResponseType

        # Proceed and get OAuth2 tokens.
        @client.getOAuthAccessToken refreshToken, opts, (err, oauth_access_token, oauth_refresh_token, results) =>
            @refreshing = false

            if err?
                logger.error "OAuth.refresh", @service, err
                return

            logger.info "OAuth.refresh", @service, oauth_access_token

            # Schedule token to be refreshed with 10% of time left.
            expires = results?.expires_in or results?.expires or 43200
            lodash.delay @refresh, expires * 900, @service

            # Save oauth details to DB and redirect user to service page.
            oauthData = {accessToken: oauth_access_token, refreshToken: oauth_refresh_token, expires: moment().add("s", expires)}
            @saveToken oauthData


# Exports
# -----------------------------------------------------------------------------
module.exports = exports = OAuth