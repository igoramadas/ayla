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
    packageJson = require "../package.json"
    url = require "url"

    # PROPERTIES
    # -------------------------------------------------------------------------

    # Holds a copy of users and tokens.
    authCache: {}

    # INIT
    # -------------------------------------------------------------------------

    # Init the Security module and refresh auth tokens from the database.
    init: =>
        @refreshAuthTokens()

    # AUTH SYNC
    # -------------------------------------------------------------------------

    # Get most recent auth tokens from the database and update the `authCache` collection.
    # Callback (err, result) is optional.
    refreshAuthTokens: (callback) =>
        @authCache = {}

        database.get "auth", (err, result) =>
            if err?
                logger.critical "Security.refreshAuthTokens", err
                callback err, false if callback?
            else
                logger.debug "Security.refreshAuthTokens", "Got #{result.length} tokens."
                for t in result
                    oauth = getOAuthClient t.service
                    @authCache[t.service] = t
                    @authCache[t.service].oauth = oauth
                if callback?
                    callback null, true

    # Save the specified auth token to the database.
    saveAuthToken: (service, token, tokenSecret, callback) =>
        now = moment().unix()
        data = {service: service, token: token, tokenSecret: tokenSecret, timestamp: now}

        # Set local auth cache.
        @authCache[service].token = token
        @authCache[service].tokenSecret = tokenSecret
        @authCache[service].timestamp = now

        # Save to database.
        database.set "auth", data, (err, result) =>
            if err?
                logger.error "Security.saveAuthToken", service, data, err
            else
                logger.debug "Security.saveAuthToken", service, data, "OK"
            if callback?
                callback err, result

    # Remove old auth tokens from the database.
    cleanAuthTokens: (callback) =>
        minTimestamp = moment().unix() - (settings.security.maxAuthTokenAgeDays * 24 * 60 * 60)
        database.del "auth", {timestamp: {$lt: minTimestamp}}, (err, result) =>
            if err?
                logger.error "Security.cleanAuthTokens", "Timestamp #{minTimestamp}", err
            else
                logger.debug "Security.cleanAuthTokens", "Timestamp #{minTimestamp}", "OK"
            if callback?
                callback err, result

    # HELPERS
    # -------------------------------------------------------------------------

    # Helper to the an OAuth client for a particular service.
    getOAuthClient = (service) ->
        callbackUrl = settings.general.appUrl + service + "/auth/callback"

        return new oauthModule.OAuth(
            settings[service].oauthUrl + "request_token",
            settings[service].oauthUrl + "access_token",
            settings[service].apiKey,
            settings[service].apiSecret,
            settings[service].oauthVersion,
            callbackUrl,
            "HMAC-SHA1",
            null,
            {"Accept": "*/*", "Connection": "close", "User-Agent": "Jarbas #{packageJson.version}"})

    # Try getting auth data for a particular request / response.
    processAuthToken: (service, options, req, res) =>
        if not @authCache[service]?
            oauth = getOAuthClient service
            @authCache[service] = {oauth: oauth}
        else
            oauth = @authCache[service]?.oauth

        # Check if request has token on querystring.
        qs = url.parse(req.url, true).query
        hasTokenVerifier = qs?.oauth_token?

        # Helper function to get the access token.
        getAccessToken = (err, oauth_token, oauth_token_secret, additionalParameters) =>
            if err?
                logger.error "Security.processAuthToken", "getAccessToken", service, oauth_token, oauth_token_secret, err
                return
            logger.debug "Security.processAuthToken", "getAccessToken", service, oauth_token, oauth_token_secret

            # Save auth details to DB and redirect user to service page.
            @saveAuthToken service, oauth_token, oauth_token_secret
            res.redirect "/#{service}"

        # Helper function to get the request token.
        getRequestToken = (err, oauth_token, oauth_token_secret, oauth_authorize_url, additionalParameters) =>
            if err?
                logger.error "Security.processAuthToken", "getRequestToken", service, oauth_token, oauth_token_secret, err
                return
            logger.debug "Security.processAuthToken", "getRequestToken", service, oauth_token, oauth_token_secret

            # Set token secret cache and redirect to authorization URL.
            @authCache[service].tokenSecret = oauth_token_secret
            res.redirect "#{settings[service].oauthUrl}authorize?oauth_token=#{oauth_token}"

        # Has the token verifier on the query string? Get OAuth access token from server.
        if hasTokenVerifier
            oauth.getOAuthAccessToken qs.oauth_token, @authCache[service].tokenSecret, qs.oauth_verifier, getAccessToken
        else
            oauth.getOAuthRequestToken {}, getRequestToken


# Singleton implementation
# -----------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()