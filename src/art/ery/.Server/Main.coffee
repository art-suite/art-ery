{defineModule, merge} = require 'art-foundation'
http = require 'http'

defineModule module, class Main
  @defaults:
    port: 8085

  @start: (options) ->
    options = merge Main.defaults, options
    {port} = options

    server = http.createServer (request, response) ->
      response.end "It Works!! #{request.url}"

    server.listen port, ->
      console.log "Art.Ery.Server listening on: http://localhost:#{port}"
