{defineModule, log, isString, present, CommunicationStatus, wordsArray} = require 'art-foundation'
{Response, Request, Pipeline, session, Session} = Neptune.Art.Ery
{clientFailure, success, failure, missing} = CommunicationStatus

isPresentString = (s) -> isString(s) && present s

defineModule module, class AuthPipeline extends Pipeline

  @suite: ->
    setup -> session.reset()

    test "clientApiMethodList", ->
      p = new AuthPipeline
      assert.eq p.clientApiMethodList, wordsArray "authenticate get setFooSession"

    test "auth success", ->
      # NOTE: a new Session is provided here only for testing - to ensure a clean session
      # Most the time you just want the default, global session:
      #   auth = new AuthPipeline()
      auth = new AuthPipeline
      auth.authenticate data: username: "bar", password: "bar"
      .then ->
        assert.eq auth.session.data, username: "bar"

    test "auth failure", ->
      auth = new AuthPipeline()
      assert.rejects auth.authenticate data: username: "bar", password: "baz"
      .then ({info: {response}}) ->
        assert.eq response.status, clientFailure
        assert.isString response.data.message

    test "auth then get", ->
      # NOTE: a new Session is provided here only for testing - to ensure a clean session
      # Most the time you just want the default, global session:
      #   auth = new AuthPipeline()
      auth = new AuthPipeline
      auth.get()
      .then (v) -> assert.eq v, {}
      .then     -> auth.authenticate data: username: "bar", password: "bar"
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

  @publicHandlers
    authenticate: (request) ->
      {data} = request
      if message = authenticationFailed data
        request.clientFailure data: message: message
      else
        request.respondWithMergedSession username: data.username

    # in order for this to work in production,
    # it has to be handled client-side
    # and that means it has to be a filter with higher priority than the highest server-side filter.
    get: ({session}) -> session

    setFooSession: (request) -> request.respondWithMergedSession foo: request.data.foo
