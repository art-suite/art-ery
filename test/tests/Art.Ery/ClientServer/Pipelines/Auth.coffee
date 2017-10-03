{defineModule, log} = require 'art-foundation'
{defineModule, log, isString, present, CommunicationStatus, wordsArray} = require 'art-foundation'
{Response, Request, Pipeline, Session} = require 'art-ery'
{success, missing} = CommunicationStatus

isPresentString = (s) -> isString(s) && present s

defineModule module, class Auth extends Pipeline

  @remoteServer "http://localhost:8085"

  # a stupid authentication test
  authenticationFailed = (data) ->
    {username, password} = data || {}
    return "username not present" unless isPresentString username
    return "password not present" unless isPresentString password
    return "username and password don't match" unless username == password

  @publicRequestTypes "get authenticate loggedInAs hello setFooSession getRestrictedResource"

  @handlers
    get: ({session}) -> session.username

    authenticate: (request) ->
      {data} = request
      if message = authenticationFailed data
        request.clientFailure data: message: message
      else
        request.respondWithMergedSession username: data.username

    # in order for this to work in production,
    # it has to be handled client-side
    # and that means it has to be a filter with higher priority than the highest server-side filter.
    loggedInAs: (request) ->
      if username = isPresentString request.session.username
        {username}
      else
        # not logged in
        request.success()

    hello: (request) ->
      request.subrequest "myRemote", "hello" # request.session.username

    setFooSession: (request) -> request.respondWithMergedSession foo: request.data.foo

    getRestrictedResource: (request) ->
      if request.session.username
        secretSauce: "thousand island dressing"
      else
        request.clientFailureNotAuthorized()