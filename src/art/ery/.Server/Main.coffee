{log, defineModule, merge, CommunicationStatus, isNumber} = require 'art-foundation'
{success} = CommunicationStatus
PromiseHttp = require './PromiseHttp'
{pipelines} = require '../'

defineModule module, class Main
  @defaults:
    port: 8085

  @start: (options) ->
    options.port = Main.defaults.port unless isNumber options.port
    log "Art.Ery.pipelines"
    for k, v of pipelines
      log "http://localhost:#{options.port}/pipelines/#{k}"

    PromiseHttp.start merge options,
      name: "Art.Ery.Server"
      handlers: [
        (request, data) ->

          data = JSON.parse data || "{}"

          console.log "handler: #{request.method} #{request.url}"
          if m = request.url.match /^\/pipelines\/([a-z_][a-z0-9_]+)(?:-([a-z0-9_]+))?(?:\/([-_.a-z0-9]+))?/i
            [__, pipelineName, requestType, key] = m
            log match:
              pipelineName: pipelineName
              requestType: requestType
              key: key
            requestType ||= request.method.toLocaleLowerCase()
            if pipeline = pipelines[pipelineName]
              log request:
                pipelineName: pipelineName
                requestType: requestType
                requestOptions: requestOptions =
                  originatedOnClient: true
                  key: key
                  data: data
              pipeline._processClientRequest requestType, requestOptions
              .then (result) ->
                headers: "Access-Control-Allow-Origin": "*"
                json: result

            else
              Promise.reject "invalid pipeline: #{pipelineName}"
          else
            headers:
              "Access-Control-Allow-Origin": "*"

            json:
              status: success
              data: "It Works!! #{request.url}"
      ]
