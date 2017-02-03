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
    delete: (request) -> request.success()

    subupdates: (request) ->
      {postId, commentId, userId, name} = request.data

      log "SUBUPDATES AWAY!"
      Promise.all([
        postId    && request.subrequest "myRemote", "create", key: postId,     data: {name}
        userId    && request.subrequest "myRemote", "update", key: userId,     data: {name}
        commentId && request.subrequest "myRemote", "delete", key: commentId
      ]).then -> request.success()

    hello: ({session}) -> "Hello, #{session.username}!"

    simulateMissing: (request) -> request.missing()

    simulateServerFailure: -> throw new Error "Boom!"

    simulateClientFailure: (request) -> request.clientFailure()

    simulatePropsInput: (request) -> request.props

    simulatePropsOutput: (request) -> request.success props: myExtras: true

    handledByFilterRequest: ->