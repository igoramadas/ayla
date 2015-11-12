# SERVER: OAUTH
# -----------------------------------------------------------------------------
# Controls authentication using OAuth1 or OAuth2.
class OAuth

    expresser = require "expresser"
    events = null
    lodash = null
    logger = null
    moment = null
    settings = null

    oauthModule = require "oauth"
    fs = require "fs"
    path = require "path"
    url = require "url"

    filename: null

    # INIT
    # -------------------------------------------------------------------------

    # Init the OAuth module and refresh auth tokens from disk.
    constructor: (@service) ->
        events = expresser.events
        lodash = expresser.libs.lodash
        logger = expresser.logger
        moment = expresser.libs.moment
        settings = expresser.settings

        logger.debug "OAuth", "New for #{@service}"

        # Used as a helper callback, triggered when a valid token has been taken
        # from the API server.
        @onAuthenticated = null

        # Set initial variables.
        @authenticated = false

        # Credentials received from server.
        @credentials = {}

        # Set filename.
        @filename = path.join __dirname, "../data/oauth/#{@service}.json"

    # AUTH SYNC
    # -------------------------------------------------------------------------

    # Get most recent auth token from the disk. Callback (err, result) is optional.
    loadToken: (callback) =>
        if not fs.existsSync @filename
            logger.warn "OAuth.loadToken", @service, "No tokens found!"

            if settings[@service].api.token?
                @credentials.token = settings[@service].api.token
                @credentials.refreshToken = settings[@service].api.refreshToken

            return

        # Read credentials from /data/oauth.
        fs.readFile @filename, "utf8", (err, result) =>
            if err?
                logger.critical "OAuth.loadToken", @service, err
                callback err, result if callback?
            else
                logger.debug "OAuth.loadToken", result

                @client = getClient @service

                # Iterate results to create OAuth clients for all users.
                if result?
                    @credentials = JSON.parse result

                    # Needs refresh?
                    if @credentials.expires? and moment().unix() > @credentials.expires
                        lodash.delay @refresh, 1000

                # Is it authenticated?
                if @credentials.token?
                    @authenticated = true
                    @onAuthenticated() if @onAuthenticated?

                # Pass data back to caller.
                if callback?
                    callback null, result

    # Save the specified auth token to disk.
    saveToken: (params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Add extra parameters like timestamp and user ID.
        @credentials.refreshToken = params.refreshToken or params.refresh
        @credentials.timestamp = params.oauth_timestamp or moment().unix()
        @credentials.userId = params.encoded_user_id if params.encoded_user_id?
        @credentials.userId = params.userid if params.userid?
        @credentials.userId = params.userId if params.userId?

        delete @credentials.refresh
        delete @credentials.encoded_user_id
        delete @credentials.userid

        # Set and trigger authenticated callback.
        # Mark as authenticated.
        @authenticated = true
        @onAuthenticated() if @onAuthenticated?

        # Clone itself to be saved to disk.
        data = @getJSON true

        # Update oauth collection and set related tokens `active` to false.
        fs.writeFile @filename, JSON.stringify(data), (err, result) =>
            if err?
                logger.error "OAuth.saveToken", data, err
            else
                logger.debug "OAuth.saveToken", data, "OK"

            if callback?
                callback err, result

    # PROCESSING AND REQUESTING
    # -------------------------------------------------------------------------

    # Helper to the an OAuth client for a particular service.
    getClient = (service) ->
        headers = {"Accept": "*/*", "Connection": "close", "User-Agent": "Ayla OAuth Client"}
        version = settings[service].api.oauthVersion
        callbackUrl = "#{settings.app.url}api/#{service}/auth/callback"

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
        if not @credentials.token?
            callback "No oauth data found. Please authorize first on #{@service}."
            return

        # OAuth2 have only an access token, OAuth1 has a token and a secret.
        if settings[@service].api.oauthVersion is "2.0"
            @client.get reqUrl, @credentials.token, (err, result) =>
                if err?
                    description = err.data?.error_description or err.data?.error?.message or null
                    @refresh() if err.statusCode is 401 or err.statusCode is 403 or description?.indexOf("expired") > 0
                callback err, result
        else
            @client.get reqUrl, @credentials.token, @credentials.tokenSecret, (err, result) =>
                callback err, result

    # Try getting OAuth data for a particular request / response.
    process: (req, res) =>
        if not @client?
            @client = getClient @service

        # Check if request has token on querystring.
        qs = url.parse(req.url, true).query if req?

        # Helper function to get the request token using OAUth 1.x.
        getRequestToken1 = (err, oauth_token, oauth_token_secret) =>
            if err?
                logger.error "OAuth.process", "getRequestToken1", @service, err
                return

            logger.info "OAuth.process", "getRequestToken1", @service, oauth_token

            # Set token secret cache and redirect to authorization URL.
            @credentials.tokenSecret = oauth_token_secret
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
            res?.redirect "/api/#{@service}"

        # Helper function to get the access token using OAUth 2.x.
        getAccessToken2 = (err, oauth_access_token, oauth_refresh_token, results) =>
            if err?
                logger.error "OAuth.process", "getAccessToken2", @service, err
                return

            # Schedule token to be refreshed automatically with 10% of the expiry time left.
            # Minimum refresh time is 1 hour.
            expires = results?.expires_in or results?.expires or 43200
            expires = 3600 if expires < 3600

            logger.info "OAuth.process", "getAccessToken2", @service, oauth_access_token, "Expires in #{expires}s"

            # Delayed refresh before token expires.
            refreshInterval = parseInt(expires) * 900
            lodash.delay @refresh, refreshInterval

            # Save oauth details to DB and redirect user to service page.
            oauthData = {token: oauth_access_token, refreshToken: oauth_refresh_token, expires: moment().add(expires, "s").unix()}
            @saveToken oauthData
            res?.redirect "/api/#{@service}"

        # Set correct request handler based on OAUth parameters and query tokens.
        if settings[@service].api.oauthVersion is "2.0"

            # Use cliend credentials (password) or authorization code?
            if settings[@service].api.username? and settings[@service].api.password?
                opts = {"grant_type": "password", username: settings[@service].api.username, password: settings[@service].api.password}
            else
                opts = {"grant_type": "authorization_code"}

            if settings[@service].api.oauthResponseType?
                opts["response_type"] = settings[@service].api.oauthResponseType

            if settings[@service].api.oauthState?
                opts["state"] = settings[@service].api.oauthState

            if settings[@service].api.oauthPassRedirect
                opts["redirect_uri"] = settings.app.url + "api/#{@service}/auth/callback"

            # Get authorization code from querystring.
            qCode = qs?.code

            if qCode?
                @client.getOAuthAccessToken qCode, opts, getAccessToken2
            else
                res.redirect @client.getAuthorizeUrl opts

        # Getting an OAuth1 access token?
        else if qs?.oauth_token?
            @client.getOAuthAccessToken qs.oauth_token, @credentials.tokenSecret, qs.oauth_verifier, getAccessToken1
        else
            @client.getOAuthRequestToken {}, getRequestToken1

    # Helper to refresh an OAuth2 token.
    refresh: =>
        if not @client?
            logger.warn "OAuth.refresh", @service, "OAuth client not ready. Abort refresh!"
            return

        # Abort if token is already being refreshed.
        minRefreshTime = moment().subtract(settings.modules.minRefreshTokenIntervalSeconds, "s").unix()
        return if @lastRefresh? and @lastRefresh > minRefreshTime

        @authenticated = false
        @lastRefresh = moment().unix()

        # Get oauth object and refresh token and set grant type to refresh_token.
        refreshToken = @credentials.refreshToken
        opts = {"grant_type": "refresh_token"}

        logger.info "OAuth.refresh", @service, refreshToken

        # Proceed and get OAuth2 tokens.
        @client.getOAuthAccessToken refreshToken, opts, (err, oauth_access_token, oauth_refresh_token, results) =>
            if err?
                logger.error "OAuth.refresh", @service, err
                return
            else if not oauth_access_token? or oauth_access_token is ""
                logger.warn "OAuth.refresh", @service, "Access token is blank!"
                return

            # Schedule token to be refreshed with 10% of time left.
            expires = results?.expires_in or results?.expires or 43200
            expires = 3600 if expires < 3600

            logger.info "OAuth.refresh", @service, oauth_access_token, "Expires #{expires}"

            # Delayed refresh before token expires.
            refreshInterval = parseInt(expires) * 900
            lodash.delay @refresh, refreshInterval

            # If no refresh token is returned, keep the last one.
            oauth_refresh_token = @credentials.refreshToken if not oauth_refresh_token? or oauth_refresh_token is ""

            # Save oauth details to DB and redirect user to service page.
            oauthData = {token: oauth_access_token, refreshToken: oauth_refresh_token, expires: moment().add(expires, "s").unix()}
            @saveToken oauthData

    # Helper to get JSON representation of the OAuth object.
    # If safe is true, return only safe values (remove tokens and confidential data).
    getJSON: (safe) =>
        data = {}

        for key, value of this
            if not lodash.isFunction value and key isnt "client"
                data[key] = lodash.cloneDeep value

        if safe
            delete data.token
            delete data.refreshToken

        return data

# Exports OAuth module.
# -----------------------------------------------------------------------------
module.exports = exports = OAuth
