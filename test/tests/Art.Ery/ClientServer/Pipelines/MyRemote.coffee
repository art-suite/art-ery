{defineModule, log, merge} = require 'art-foundation'
{Pipeline, TimestampFilter, DataUpdatesFilter} = require 'art-ery'

defineModule module, class MyRemote extends Pipeline

  @remoteServer "http://localhost:8085"

  @filter
    name: "handleByFilter"
    before: handledByFilterRequest: (request) -> request.success()

  @filter
    name: "FakeTimestampFilter"
    after: all: (response) ->
      log FakeTimestampFilter: {response}
      {type} = response
      out = null
      if type == "create" || type == "update"
        (out||={}).updatedAt = 123456789
        if type == "create"
          out.createdAt = 123456789
        response.withMergedData out
      else
        response

  @filter
    before: filterClientFailure: (request) ->
      request.require false, "filter allways fails"

  @publicRequestTypes "
    get
    hello
    simulateServerFailure
    simulateClientFailure
    simulatePropsInput
    simulatePropsOutput
    handledByFilterRequest
    setSessionA
    setSessionB
    handlerClientFailure
    privateRequestOkAsSubRequest
    returnFalse
    "

  @handlers
    get: ({key, data}) -> "#{data?.greeting || 'Hello'} #{key || 'World'}!"

    hello: ({session}) -> "Hello, #{session.username}!"

    returnFalse: -> false

    simulateMissing: (request) -> request.missing()

    simulateServerFailure: -> throw new Error "Boom!"

    simulateClientFailure: (request) -> request.clientFailure()

    simulatePropsInput: (request) -> request.props

    simulatePropsOutput: (request) -> request.success props: myExtras: true

    handledByFilterRequest: ->

    setSessionA: (request) -> request.respondWithMergedSession sessionA: true
    setSessionB: (request) -> request.respondWithMergedSession sessionB: true

    handlerClientFailure: (request) -> request.require false, "handler allways fails"

    myPrivateRequestType: (request) ->
      request.requireServerOrigin().then -> "myPrivateRequestType success"

    privateRequestOkAsSubRequest: (request) ->
      request.subrequest request.pipeline, "myPrivateRequestType"
