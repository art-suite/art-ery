{newObjectFromEach, objectKeyCount, log, defineModule, merge, CommunicationStatus, isNumber} = require 'art-foundation'
{success} = CommunicationStatus
PromiseHttp = require './PromiseHttp'
{pipelines} = require '../'
PromiseJsonWebToken = require './PromiseJsonWebToken'

###
generating a secury HMAC sessionKey:

in short, run: openssl rand -base64 16

http://security.stackexchange.com/questions/95972/what-are-requirements-for-hmac-secret-key
Recommends 128bit string generated with a "cryptographically
secure pseudo random number generator (CSPRNG)."

http://osxdaily.com/2011/05/10/generate-random-passwords-command-line/
# 128 bits:
> openssl rand -base64 16

# 256 bits:
> openssl rand -base64 32

###
sessionKey = "todo+generate+your+one+unique+key" # 22 base64 characters == 132 bits


defineModule module, ->
  class Main
    @defaults:
      port: 8085

    httpMethodsToArtEryRequestTypes =
      get:    "get"
      post:   "create"
      put:    "update"
      delete: "delete"

    @findPipelineForRequest: (request) ->
      {url} = request
      for pipelineName, pipeline of pipelines
        if m = url.match pipeline.restPathRegex
          [__, type, key] = m
          type ||= httpMethodsToArtEryRequestTypes[request.method.toLocaleLowerCase()]
          return {pipeline, type, key} if type

      null

    @signSession: (plainObjectsResponse) ->
      {session} = plainObjectsResponse
      PromiseJsonWebToken.sign session
      if session
        PromiseJsonWebToken.sign session, sessionKey
        .then (sessionSignature) -> merge plainObjectsResponse, {sessionSignature}
      else
        Promise.resolve plainObjectsResponse

    @artEryPipelineApiHandler: (request, requestBody) ->

      if found = Main.findPipelineForRequest request
        {pipeline, type, key} = found

        requestOptions = {
          type
          key
          originatedOnClient: true
          data:     merge requestBody.query, requestBody.data
          session:  requestBody.session || {}
        }

        return pipeline._processRequest requestOptions
        .then (response) ->
          Main.signSession response.plainObjectsResponse

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
