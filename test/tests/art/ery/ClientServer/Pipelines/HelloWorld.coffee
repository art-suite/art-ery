{defineModule, log} = require 'art-foundation'
{Pipeline} = Neptune.Art.Ery

defineModule module, class HelloWorld extends Pipeline

  remoteServer: "http://localhost:8085"

  @handlers
    get: ({data}) -> "Hello #{data?.name || 'World'}!"
