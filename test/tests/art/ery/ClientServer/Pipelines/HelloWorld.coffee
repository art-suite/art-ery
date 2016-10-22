{defineModule, log} = require 'art-foundation'
{Pipeline} = require 'art-ery'

defineModule module, class HelloWorld extends Pipeline

  remoteServerInfo:
    domain: "localhost"
    port: 8085
    apiRoot: "api"
    protocol: "https"

  @handlers
    get: ({key}) -> "Hello #{key || 'World'}!"
