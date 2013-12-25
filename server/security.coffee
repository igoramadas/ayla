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
    querystring = require "querystring"
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

        database.get "auth", {active: true}, (err, result) =>
            if err?
                logger.critical "Security.refreshAuthTokens", err
                callback err, false if callback?
            else
                for t in result
                    @authTokens[t.service] = t
                callback null, true if callback?

    # Save user info or tokens to the database.
    saveAuthTokens: (user, callback) =>
        database.set "auth", user, (err, result) =>
            if err?
                logger.error "Security.saveAuthTokens", user.id, err
            if callback?
                callback err, result

    # HELPERS
    # -------------------------------------------------------------------------

    # Try getting auth data for a particular request / response.
    processAuthToken: (service, oauth, req, res, callback) =>
        sess = JSON.parse req.cookies["#{service}Auth"]
        qs = url.parse(req.url, true).query

        # Check if request has token and secret.
        hasSecret = sess?.token_secret
        hasToken = qs?.oauth_token

        # Helper function to get the access token.
        getAccessToken = (err, oauth_token, oauth_token_secret, additionalParameters) ->
            if err?
                logger.error "Security.fetchAuthToken", "getAccessToken", service, err
                return callback err, null
            callback null, {oauth_token: oauth_token, oauth_token_secret: oauth_token_secret}

        # Helper function to get the request token.
        getRequestToken = (err, oauth_token, oauth_token_secret, oauth_authorize_url, additionalParameters) ->
            if err?
                logger.error "Security.fetchAuthToken", "getRequestToken", service, err
                return callback err, null

            cookieData = utils.minifyJson {token_secret: oauth_token_secret}, true
            cookieOptions = {path: "/", httpOnly: false}
            res.cookie "#{service}Auth", cookieData, cookieOptions
            res.redirect "#{settings[service].authUrl}authorize?oauth_token=#{oauth_token}"

        # Has secret and token? Get OAuth access token from server.
        if hasSecret and hasToken
            oauth.getOAuthAccessToken qs.oauth_token, sess.tokenSecret, qs.oauth_verifier, getAccessToken
        else
            oauth.getOAuthRequestToken {oauth_callback: callbackURI}, getRequestToken


# Singleton implementation
# -----------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()