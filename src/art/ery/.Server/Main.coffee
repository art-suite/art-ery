{log, defineModule, merge, CommunicationStatus} = require 'art-foundation'
{success} = CommunicationStatus
PromiseHttp = require './PromiseHttp'

defineModule module, class Main
  @defaults:
    port: 8085

  @start: (options) ->
    options = merge Main.defaults, options

    PromiseHttp.start merge options,
      name: "Art.Ery.Server"
      handlers: [
        (request, data) ->
          if request.url.match /^\/
          headers:
            "Access-Control-Allow-Origin": "*"

          json:
            status: success
            data: "It Works!! #{request.url}"
      ]
