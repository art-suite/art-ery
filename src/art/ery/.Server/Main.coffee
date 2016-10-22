{newObjectFromEach, objectKeyCount, log, defineModule, merge, CommunicationStatus, isNumber} = require 'art-foundation'
{success} = CommunicationStatus
PromiseHttp = require './PromiseHttp'
{pipelines} = require '../'

defineModule module, ->
  class Main
    @defaults:
      port: 8085

    httpMethodsToArtEryRequestTypes =
      get:    "get"
      post:   "create"
      put:    "update"
      delete: "delete"

    @artEryPipelineApiHandler:
      (request, requestBody) ->
        {url} = request
        # log artEryPipelineApiHandler:
        #   method: request.method
        #   url: request.url
        #   pipelines: Object.keys pipelines
        for pipelineName, pipeline of pipelines
          {restPathRegex, restPath} = pipeline
          # log "FOO!"
          # log artEryPipelineApiHandler:
          #   pipelineName: pipelineName
          #   restPath: restPath
          #   restPathRegex: restPathRegex
          #   url: url
          if m = url.match restPathRegex
            [__, requestType, key] = m
            # log artEryPipelineApiHandler:
            #   match: pipelineName
            #   requestType: requestType
            #   key: key
            #   m: m
            requestType ||= httpMethodsToArtEryRequestTypes[request.method.toLocaleLowerCase()]
            return false unless requestType # not handled

            requestOptions =
              type: requestType
              originatedOnClient: true
              key: key
              data: requestBody.data
              session: requestBody.session || {}

            # log "artEryPipelineApiHandler: I can handle this!":
            #   pipeline: pipelineName
            #   requestType: requestType
            #   requestOptions: requestOptions

            return pipeline._processRequest requestOptions
            .then (response) ->
              # log "artEryPipelineApiHandler", response.jsonResponse
              response.jsonResponse
          # else
          #   log artEryPipelineApiHandler: nomatch: pipelineName
        null

    @getArtEryPipelineApiInfo: (options = {}) ->
      # log options: options
      {server, port} = options
      server ||= "http://localhost"
      server += ":#{port}" if port

      "Art.Ery.pipeline.json.rest.api":
        newObjectFromEach pipelines, (pipeline) -> pipeline.getApiReport server: server

    @start: (options) ->
      options.port = Main.defaults.port unless isNumber options.port
      log @getArtEryPipelineApiInfo options
      throw new Error "no pipelines" unless 0 < objectKeyCount pipelines

      PromiseHttp.start merge options,
        name: "Art.Ery.Server"
        commonResponseHeaders: "Access-Control-Allow-Origin": "*"
        apiHandlers: [
          @artEryPipelineApiHandler
          => @getArtEryPipelineApiInfo options
        ]

            # else
            #   status: success
            #   data: "It Works!! #{request.url}"
