{defineModule, log} = require 'art-foundation'
{Pipeline, TimestampFilter, DataUpdatesFilter} = require 'art-ery'

defineModule module, class MyRemote extends Pipeline

  @remoteServer "http://localhost:8085"

  @filter
    name: "handleByFilter"
    before: handledByFilterRequest: (request) -> request.success()

  @filter TimestampFilter
  @filter DataUpdatesFilter

  @handlers
    get: ({key, data}) -> "#{data?.greeting || 'Hello'} #{key || 'World'}!"

    create: ({data}) -> data
    update: ({data}) -> data

    subupdates: (request) ->
      {d1, d2} = request.data

      Promise.all([
        request.subrequest "myRemote", "update", data: d1
        request.subrequest "myRemote", "update", data: d2
      ]).then -> request.success()

    hello: ({session}) -> "Hello, #{session.username}!"

    simulateMissing: (request) -> request.missing()

    simulateServerFailure: -> throw new Error "Boom!"

    simulateClientFailure: (request) -> request.clientFailure()

    simulatePropsInput: (request) -> request.props

    simulatePropsOutput: (request) -> request.success props: myExtras: true

    handledByFilterRequest: ->