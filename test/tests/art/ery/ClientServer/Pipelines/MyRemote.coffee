{defineModule, log} = require 'art-foundation'
{Pipeline, TimestampFilter, DataUpdatesFilter} = require 'art-ery'

defineModule module, class MyRemote extends Pipeline

  @remoteServer "http://localhost:8085"

  @filter
    name: "handleByFilter"
    before: handledByFilterRequest: (request) -> request.success()

  @filter
    name: "FakeTimestampFilter"
    after: all: (response) ->
      {type} = response
      out = null
      if type == "create" || type == "update"
        (out||={}).updatedAt = 123456789
        if type == "create"
          out.createdAt = 123456789
        response.withMergedData out
      else
        response

  @filter DataUpdatesFilter

  @handlers
    get: ({key, data}) -> "#{data?.greeting || 'Hello'} #{key || 'World'}!"

    create: ({data}) -> data
    update: ({data}) -> data

    subupdates: (request) ->
      {postId, commentId, name} = request.data

      Promise.all([
        request.subrequest "myRemote", "create", key: postId,     data: {name}
        request.subrequest "myRemote", "update", key: commentId,  data: {name}
      ]).then -> request.success()

    hello: ({session}) -> "Hello, #{session.username}!"

    simulateMissing: (request) -> request.missing()

    simulateServerFailure: -> throw new Error "Boom!"

    simulateClientFailure: (request) -> request.clientFailure()

    simulatePropsInput: (request) -> request.props

    simulatePropsOutput: (request) -> request.success props: myExtras: true

    handledByFilterRequest: ->