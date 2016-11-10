{defineModule, log} = require 'art-foundation'
{Pipeline} = require 'art-ery'

defineModule module, class HelloWorld extends Pipeline

  remoteServerInfo:
    domain: "localhost"
    port: 8085
    protocol: "http"

  @filter
    name: "handleByFilter"
    before: handledByFilterRequest: (request) ->
      request.success()
      .then (response) ->
        log handledByFilterRequest: response: response
        response

  @handlers
    get: ({key}) -> "Hello #{key || 'World'}!"

    missing: (request) -> request.missing()

    handledByFilterRequest: ->