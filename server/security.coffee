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

        database.get "authCache", {"active": true}, (err, result) =>
            if err?
                logger.critical "Security.refreshAuthTokens", err
                callback err, false if callback?
            else
                logger.debug "Security.refreshAuthTokens", result
                for t in result
                    oauth = getOAuthClient t.service
                    @authCache[t.service] = {oauth: oauth, data: t}
                if callback?
                    callback null, true

    # Save the specified auth token to the database.
    saveAuthToken: (service, token, tokenSecret, params, callback) =>
        if not callback? and lodash.isFunction params
            callback = params
            params = null

        # Get current time and set data.
        now = moment().unix()
        data = {service: service, active: true, token: token, tokenSecret: tokenSecret, timestamp: now}

        # Add extra parameters, if any.
        if params?
            data.timestamp = params.oauth_timestamp if params.oauth_timestamp?
            data.userId = params.encoded_user_id if params.encoded_user_id?
            data.userId = params.userid if params.userid?

        # Set local auth cache.
        @authCache[service].data = data

        # Update current "authCache" collection and set related tokens `active` to false.
        database.set "authCache", {active: false}, {patch: true, upsert: false, filter: {service: service}}, (err, result) =>
            if err?
                logger.error "Security.saveAuthToken", service, "Set active=false", err
            else
                logger.debug "Security.saveAuthToken", service, "Set active=false", "OK"

            # Save to database.
            database.set "authCache", data, (err, result) =>
                if err?
                    logger.error "Security.saveAuthToken", service, data, err
                else
                    logger.debug "Security.saveAuthToken", service, data, "OK"
                if callback?
                    callback err, result

    # Remove old auth tokens from the database.
    cleanAuthTokens: (callback) =>
        minTimestamp = moment().unix() - (settings.security.maxAuthTokenAgeDays * 24 * 60 * 60)
        database.del "authCache", {timestamp: {$lt: minTimestamp}}, (err, result) =>
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
        if not res?
            res = req
            req = options
            options = null

        # Check if OAuth client was already created, if not then create one.
        if not @authCache[service]?
            oauth = getOAuthClient service
            @authCache[service] = {oauth: oauth, data: {}}
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
            @saveAuthToken service, oauth_token, oauth_token_secret, additionalParameters
            res.redirect "/#{service}"

        # Helper function to get the request token.
        getRequestToken = (err, oauth_token, oauth_token_secret, oauth_authorize_url, additionalParameters) =>
            if err?
                logger.error "Security.processAuthToken", "getRequestToken", service, oauth_token, oauth_token_secret, err
                return
            logger.debug "Security.processAuthToken", "getRequestToken", service, oauth_token, oauth_token_secret

            # Set token secret cache and redirect to authorization URL.
            @authCache[service].data.tokenSecret = oauth_token_secret
            res.redirect "#{settings[service].oauthUrl}authorize?oauth_token=#{oauth_token}"

        # Has the token verifier on the query string? Get OAuth access token from server.
        if hasTokenVerifier
            oauth.getOAuthAccessToken qs.oauth_token, @authCache[service].data.tokenSecret, qs.oauth_verifier, getAccessToken
        else
            oauth.getOAuthRequestToken {}, getRequestToken


# Singleton implementation
# -----------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()