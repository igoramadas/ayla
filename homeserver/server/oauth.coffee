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

    # INIT
    # -------------------------------------------------------------------------

    # Init the OAuth module and refresh auth tokens from the database.
    constructor: (@service) ->
        logger.debug "OAuth", "New for #{@service}"

        @data = {}

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

                @client = getClient @service

                # Iterate results to create OAuth clients for all users.
                for t in result
                    @data = t

                    # Needs refresh?
                    @refresh() if t.expires? and moment().unix() > t.expires

                # If no tokes are found, check if it was specified on the settings.
                if result.length < 1 and settings[@service].api.accessToken?
                    @data.accessToken = settings[@service].api.accessToken
                    @data.refreshToken = settings[@service].api.refreshToken
                    result =[{accessToken: settings[@service].api.accessToken}]

                # Pass data back to caller.
                if callback?
                    callback null, result

    # Remove old auth tokens from the database.
    cleanTokens: (callback) =>
        minTimestamp = moment().unix() - (settings.modules.maxAuthTokenAgeDays * 24 * 60 * 60)
        filter = {"active": false, "timestamp": {$lt: minTimestamp}}

        # Delete old unactive tokens.
        database.delete "oauth", filter, (err, result) =>
            if err?
                logger.error "OAuth.cleanTokens", "Timestamp #{minTimestamp}", err
            else
                logger.info "OAuth.cleanTokens", "Deleted older than #{minTimestamp}."

            if callback?
                callback err, result

    # Save the specified auth token to the database.
    saveToken: (params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get current time and set data.
        now = moment().unix()
        @data = lodash.defaults params, {service: @service, active: true, timestamp: now}

        # Add extra parameters like timestamp and user ID.
        @data.timestamp = params.oauth_timestamp if params.oauth_timestamp?
        @data.userId = params.encoded_user_id if params.encoded_user_id?
        @data.userId = params.userid if params.userid?
        @data.userId = params.userId if params.userId?
        delete @data.userid

        # Update oauth collection and set related tokens `active` to false.
        database.update "oauth", {active: false}, {patch: true, upsert: false, filter: {service: @service}}, (err, result) =>
            if err?
                logger.error "OAuth.saveToken", @service, "Set active=false", err
            else
                logger.debug "OAuth.saveToken", @service, "Set active=false", "OK"

            # Save to database.
            database.insert "oauth", @data, (err, result) =>
                if err?
                    logger.error "OAuth.saveToken", @service, @data, err
                else
                    logger.debug "OAuth.saveToken", @service, @data, "OK"

                if callback?
                    callback err, result

    # PROCESSING AND REQUESTING
    # -------------------------------------------------------------------------

    # Helper to the an OAuth client for a particular service.
    getClient = (service) ->
        headers = {"Accept": "*/*", "Connection": "close", "User-Agent": "Ayla OAuth Client"}
        version = settings[service].api.oauthVersion

        # Callback URL is set to localhost in case debug is true.
        if not settings.general.debug
            callbackUrl = settings.general.appUrl
        else if settings.app.ssl.enabled
            callbackUrl = "https://localhost:#{settings.app.port}/"
        else
            callbackUrl = "http://localhost:#{settings.app.port}/"

        callbackUrl += service + "/auth/callback"

        # Create OAuth 2.0 or 1.0 client depending on parameters.
        if version is "2.0"
            obj = new oauthModule.OAuth2(
                settings[service].api.clientId,
                settings[service].api.secret,
                settings[service].api.oauthUrl,
                settings[service].api.oauthPathAuthorize,
                settings[service].api.oauthPathToken,
                headers)
        else
            obj = new oauthModule.OAuth(
                settings[service].api.oauthUrl + "request_token",
                settings[service].api.oauthUrl + "access_token",
                settings[service].api.clientId,
                settings[service].api.secret,
                version,
                callbackUrl,
                "HMAC-SHA1",
                null,
                headers)

        # Use authorization header instead of passing token via querystrings?
        if settings[service].api.oauthUseHeader?
            obj.useAuthorizationHeaderforGET settings[service].api.oauthUseHeader

        return obj

    # Get an OAuth protected resource.
    get: (reqUrl, callback) =>
        if not @data?
            callback "No oauth data found. Please authorize first on #{@service}."
            return

        # OAuth2 have only an access token, OAuth1 has a token and a secret.
        if settings[@service].api.oauthVersion is "2.0"
            @client.get reqUrl, @data.accessToken, (err, result) =>
                if err?
                    description = err.data?.error_description or err.data?.error?.message or null
                    @refresh() if err.statusCode is 403 or description?.indexOf("expired") > 0
                callback err, result
        else
            @client.get reqUrl, @data.token, @data.tokenSecret, (err, result) =>
                callback err, result

    # Try getting OAuth data for a particular request / response.
    process: (req, res) =>
        if not @client?
            @client = getClient @service
            @data = {}

        # Check if request has token on querystring.
        qs = url.parse(req.url, true).query if req?

        # Helper function to get the request token using OAUth 1.x.
        getRequestToken1 = (err, oauth_token, oauth_token_secret, additionalParameters) =>
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

            # Schedule token to be refreshed automatically with 10% of the expiry time left.
            expires = results?.expires_in or results?.expires or 43200
            expires = 3600 if expires < 3600

            logger.info "OAuth.process", "getAccessToken2", @service, oauth_access_token, "Expires #{expires}"

            # Delayed refresh before token expires.
            refreshInterval = parseInt(expires) * 900
            lodash.delay @refresh, refreshInterval

            # Save oauth details to DB and redirect user to service page.
            oauthData = {accessToken: oauth_access_token, refreshToken: oauth_refresh_token, expires: moment().add(expires, "s").unix()}
            @saveToken oauthData
            res?.redirect "/#{@service}"

        # Set correct request handler based on OAUth parameters and query tokens.
        if settings[@service].api.oauthVersion is "2.0"

            # Use cliend credentials (password) or authorization code?
            if settings[@service].api.username?
                opts = {"grant_type": "password", username: settings[@service].api.username, password: settings[@service].api.password}
            else
                opts = {"grant_type": "authorization_code"}

            if settings[@service].api.oauthResponseType?
                opts["response_type"] = settings[@service].api.oauthResponseType

            if settings[@service].api.oauthState?
                opts["state"] = settings[@service].api.oauthState

            if settings[@service].api.oauthPassRedirect
                opts["redirect_uri"] = settings.general.appUrl + @service + "/auth"

            # Get authorization code from querystring.
            qCode = qs?.code

            if qCode?
                @client.getOAuthAccessToken qCode, opts, getAccessToken2
            else
                res.redirect @client.getAuthorizeUrl opts

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

        # Proceed and get OAuth2 tokens.
        @client.getOAuthAccessToken refreshToken, opts, (err, oauth_access_token, oauth_refresh_token, results) =>
            @refreshing = false

            if err?
                logger.error "OAuth.refresh", @service, err
                return

            # Schedule token to be refreshed with 10% of time left.
            expires = results?.expires_in or results?.expires or 43200
            expires = 3600 if expires < 3600

            logger.info "OAuth.refresh", @service, oauth_access_token, "Expires #{expires}"

            # Delayed refresh before token expires.
            refreshInterval = parseInt(expires) * 900
            lodash.delay @refresh, refreshInterval

            # If no refresh token is returned, keep the last one.
            oauth_refresh_token = @data.refreshToken if not oauth_refresh_token? or oauth_refresh_token is ""

            # Save oauth details to DB and redirect user to service page.
            oauthData = {accessToken: oauth_access_token, refreshToken: oauth_refresh_token, expires: moment().add(expires, "s").unix()}
            @saveToken oauthData

# Exports
# -----------------------------------------------------------------------------
module.exports = exports = OAuth
