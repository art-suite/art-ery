{log, isString, present, CommunicationStatus, wordsArray} = require 'art-foundation'
{Response, Request, Pipeline, Session} = require 'art-ery'
{success, failure, missing} = CommunicationStatus

isPresentString = (s) -> isString(s) && present s

module.exports = class AuthPipeline extends Pipeline

  @suite: ->
    test "clientApiMethodList", ->
      p = new AuthPipeline
      assert.eq p.clientApiMethodList, wordsArray "authenticate"

    test "auth success", ->
      # NOTE: a new Session is provided here only for testing - to ensure a clean session
      # Most the time you just want the default, global session:
      #   auth = new AuthPipeline()
      auth = new AuthPipeline session: new Session
      auth.authenticate username: "bar", password: "bar"
      .then ->
        assert.eq auth.session.data, username: "bar"

    test "auth failure", ->
      auth = new AuthPipeline()
      auth.authenticate username: "bar", password: "baz"
      .then ->
        throw new Error "should not succeed"
      .catch (response) ->
        assert.eq response.status, failure
        assert.isString response.error.message

  ###
  a stupid authentication test
  ###
  authenticationFailed = (data) ->
    {username, password} = data
    return "username not present" unless isPresentString username
    return "password not present" unless isPresentString password
    return "username and password don't match" unless username == password

  @handlers
    authenticate: (request) ->
      {data} = request
      if message = authenticationFailed data
        request.failure error: message
      else
        request.success session: username: data.username
