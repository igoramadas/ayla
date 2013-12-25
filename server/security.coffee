# SERVER: SECURITY
# -----------------------------------------------------------------------------
# Controls authentication with users and external APIs.
class Security

    expresser = require "expresser"
    database = expresser.database
    logger = expresser.logger
    settings = expresser.settings
    utils = expresser.utils

    crypto = require "crypto"
    lodash = require "lodash"
    moment = require "moment"
    oauthModule = require "oauth"
    url = require "url"


    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds a copy of users and tokens.
    authTokens: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the Security module. Set session management methods and init
    # auth procedures for all API modules.
    init: =>
        @refreshAuthTokens()

    # AUTH SYNC
    # -------------------------------------------------------------------------

    # Get most recent auth tokens from the database and update the `authTokens` collection.
    # Callback (err, result) is optional.
    refreshAuthTokens: (callback) =>
        @authTokens = {}

        database.get "auth", (err, result) =>
            if err?
                logger.critical "Security.refreshAuthTokens", err
                callback err, false if callback?
            else
                for t in result
                    @authTokens[t.service] = t
                callback null, true if callback?

    # Save user info or tokens to the database.
    saveAuthToken: (service, data, callback) =>
        data.service = service
        @authTokens[service] = data

        database.set "auth", data, (err, result) =>
            if err?
                logger.error "Security.saveAuthToken", service, data, err
            else
                logger.debug "Security.saveAuthToken", service, data, "OK"
            if callback?
                callback err, result

    # HELPERS
    # -------------------------------------------------------------------------

    # Try getting auth data for a particular request / response.
    processAuthToken: (service, options, req, res) =>
        callbackUrl = settings.general.appUrl + service + "/auth/callback"

        @authTokens[service] = {} if not @authTokens[service]?

        # Create OAuth client.
        oauth = new oauthModule.OAuth(
            settings[service].oauthUrl + "request_token",
            settings[service].oauthUrl + "access_token",
            settings[service].apiKey,
            settings[service].apiSecret,
            options.version,
            callbackUrl,
            "HMAC-SHA1",
            null,
            {"Accept": "*/*", "Connection": "close", "User-Agent": "Jarbas"})

        # Check if request has token on querystring.
        qs = url.parse(req.url, true).query
        hasTokenVerifier = qs?.oauth_token?

        # Helper function to get the access token.
        getAccessToken = (err, oauth_token, oauth_token_secret, additionalParameters) =>
            if err?
                logger.error "Security.processAuthToken", "getAccessToken", service, oauth_token, oauth_token_secret, err
                return
            @saveAuthToken service, {token: oauth_token, tokenSecret: oauth_token_secret}
            res.redirect "/#{service}"

        # Helper function to get the request token.
        getRequestToken = (err, oauth_token, oauth_token_secret, oauth_authorize_url, additionalParameters) =>
            if err?
                logger.error "Security.processAuthToken", "getRequestToken", service, oauth_token, oauth_token_secret, err
                return

            @authTokens[service].tokenSecret = oauth_token_secret

            res.redirect "#{settings[service].oauthUrl}authorize?oauth_token=#{oauth_token}"

        # Has the token verifier on the query string? Get OAuth access token from server.
        if hasTokenVerifier
            oauth.getOAuthAccessToken qs.oauth_token, @authTokens[service].tokenSecret, qs.oauth_verifier, getAccessToken
        else
            oauth.getOAuthRequestToken {oauth_callback: callbackUrl}, getRequestToken


# Singleton implementation
# -----------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()