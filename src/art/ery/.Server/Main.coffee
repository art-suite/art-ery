throng  = require 'throng'

{select, objectWithout, newObjectFromEach, objectKeyCount, log, defineModule, merge, CommunicationStatus, isNumber} = require 'art-foundation'
{success} = CommunicationStatus
PromiseHttp = require './PromiseHttp'
{pipelines} = require '../'
PromiseJsonWebToken = require './PromiseJsonWebToken'

###
generating a secury HMAC privateSessionKey:

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
privateSessionKey = "todo+generate+your+one+unique+key" # 22 base64 characters == 132 bits


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

    ###
    NOTE: sessions expire after 30 days of inactivity; expiration is renewed every request.
      TODO:
      1) for your app, have a server-backend session record that can be manually expired
         and store it's id in the session object
      2) have a short-term expiration value you set in the session (5m - 1h)
      3) check server-backend session for manual expiration after every short-term expiration
      *) Use an ArtEry filter to do this. I'll probably write one and include it in ArtEry.Filters soon.
        BUT it won't be tied to a specific backend; you'll still have to do that part yourself.
    ###
    @signSession: signSession = (plainObjectRequest, plainObjectsResponse) ->
      {session} = plainObjectsResponse
      PromiseJsonWebToken.sign(
        objectWithout session || plainObjectRequest.session || {}, "exp"
        privateSessionKey
        expiresIn: "30 days"
      )
      .then (sessionSignature) -> merge plainObjectsResponse, {sessionSignature}

    ###
    IN: plainObjectsRequest
      .sessionSignature - required
    OUT: (promise) verified session or {} if not valid
    ###
    @verifySession: verifySession = (plainObjectsRequest) ->
      {sessionSignature} = plainObjectsRequest
      return Promise.resolve({}) unless sessionSignature
      PromiseJsonWebToken.verify sessionSignature, privateSessionKey
      .then (session) -> session
      .catch (e)-> {}

    @artEryPipelineApiHandler: (request, plainObjectRequest) ->

      if found = Main.findPipelineForRequest request

        verifySession plainObjectRequest
        .then (session) ->
          {pipeline, type, key} = found

          requestOptions =
            type:     type
            key:      key
            originatedOnClient: true
            data:     merge plainObjectRequest.query, plainObjectRequest.data
            session:  session

          pipeline._processRequest requestOptions
          .then ({plainObjectsResponse}) ->
            signSession plainObjectRequest, plainObjectsResponse

    @getArtEryPipelineApiInfo: (options = {}) ->
      {server, port} = options
      server ||= "http://localhost"
      server += ":#{port}" if port

      "Art.Ery.pipeline.json.rest.api":
        newObjectFromEach pipelines, (pipeline) -> pipeline.getApiReport server: server

    @start: (options) ->
      options.port = Main.defaults.port unless isNumber options.port
      options.port |= 0
      throw new Error "no pipelines" unless 0 < objectKeyCount pipelines

      {numWorkers} = options

      startSingleServer = =>
        PromiseHttp.start merge options,
          name: "Art.Ery.Server"
          commonResponseHeaders: "Access-Control-Allow-Origin": "*"
          apiHandlers: [
            @artEryPipelineApiHandler
            => @getArtEryPipelineApiInfo options
          ]

      if numWorkers > 1
        throng
          start:    startSingleServer
          workers:  numWorkers
          lifetime: Infinity
      else
        startSingleServer()