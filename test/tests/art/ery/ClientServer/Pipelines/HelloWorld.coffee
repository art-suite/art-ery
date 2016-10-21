{defineModule, log} = require 'art-foundation'
{Pipeline} = require 'art-ery'

defineModule module, class HelloWorld extends Pipeline

  remoteServer: "http://localhost:8085"

  @handlers
    get: ({key}) -> "Hello #{key || 'World'}!"
