{defineModule, log} = require 'art-foundation'
{Pipeline} = require 'art-ery'

defineModule module, class MyRemote extends Pipeline

  remoteServerInfo:
    domain: "localhost"
    port: 8085
    protocol: "http"

  @filter
    name: "handleByFilter"
    before: handledByFilterRequest: (request) -> request.success()

  @handlers
    get: ({key}) -> "Hello #{key || 'World'}!"

    missing: (request) -> request.missing()

    handledByFilterRequest: ->