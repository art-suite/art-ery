{defineModule, log, isString, present, CommunicationStatus, wordsArray} = require 'art-foundation'
{Response, Request, Pipeline, Session} = Neptune.Art.Ery
{success, failure, missing} = CommunicationStatus

isPresentString = (s) -> isString(s) && present s

defineModule module, class AuthPipeline extends Pipeline

  @suite: ->
    test "clientApiMethodList", ->
      p = new AuthPipeline
      assert.eq p.clientApiMethodList, wordsArray "authenticate get"

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

    test "auth then get", ->
      # NOTE: a new Session is provided here only for testing - to ensure a clean session
      # Most the time you just want the default, global session:
      #   auth = new AuthPipeline()
      auth = new AuthPipeline session: new Session
      auth.get()
      .then (v) -> assert.eq v, {}
      .then     -> auth.authenticate username: "bar", password: "bar"
      .then     -> auth.get()
      .then (v) -> assert.eq v, username: "bar"

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

    # in order for this to work in production,
    # it has to be handled client-side
    # and that means it has to be a filter with higher priority than the highest server-side filter.
    get: ({session}) -> session
