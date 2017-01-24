throng  = require 'throng'
require 'colors'

{
  BaseObject
  select, objectWithout, object, objectKeyCount, log, defineModule, merge, CommunicationStatus, isNumber
  ConfigRegistry
  deepMerge
} = require 'art-foundation'
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

ArtEry = require 'art-ery'


defineModule module, ->
  class Main extends BaseObject
    @defaults:
      port: 8085

    httpMethodsToArtEryRequestTypes =
      get:    "get"
      post:   "create"
      put:    "update"
      delete: "delete"


    @start: (options) =>
      new @(options).start()

    constructor: (@options = {}) ->
      ArtEry.config.location = "server"
      {@numWorkers, @port} = @options

    @property "port numWorkers"

    @setter
      port: (port) -> @_port = (port || Main.defaults.port) | 0

    @findPipelineForRequest: (request) ->
      {url} = request
      for pipelineName, pipeline of pipelines
        if match = url.match pipeline.restPathRegex
          # log findPipelineForRequest: {match, url}
          [__, type, key] = match
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
    signSession: signSession = (plainObjectRequest, plainObjectsResponse) ->
      {session} = plainObjectsResponse
      if session
        PromiseJsonWebToken.sign(
          objectWithout session || plainObjectRequest.session || {}, "exp"
          privateSessionKey
          expiresIn: "30 days"
        )
        .then (signature) -> merge plainObjectsResponse, session: merge session, {signature}
      else
        plainObjectsResponse

    ###
    IN: plainObjectsRequest:
      session:         # encrypted session string
      query: session:  # encrypted session string
    OUT: (promise) verified session or {} if not valid
    ###
    verifySession: verifySession = (plainObjectsRequest) ->
      {session, query} = plainObjectsRequest
      unless sessionSignature = session || query?.session
        Promise.resolve({})
      else
        PromiseJsonWebToken.verify sessionSignature, privateSessionKey
        .then (session) -> session
        .catch (e)->
          log.error "session failed validation"
          {}

    artEryPipelineApiHandler: (request, plainObjectRequest) ->
      if found = Main.findPipelineForRequest request
        verifySession plainObjectRequest
        .then (session) ->
          {url} = request
          {pipeline, type, key} = found
          {query, data} = plainObjectRequest
          # log artEryPipelineApiHandler: {pipeline, type, key, query, data, url}

          requestOptions =
            type:     type
            key:      key
            originatedOnClient: true
            data:     deepMerge query?.data, data
            session:  session

          pipeline._processRequest requestOptions
          .then ({plainObjectsResponse}) ->
            signSession plainObjectRequest, plainObjectsResponse

    getArtEryPipelineApiInfo: ->
      {server, port} = @
      server ||= "http://localhost"
      server += ":#{port}" if port

      "Art.Ery.pipeline.json.rest.api":
        object pipelines, (pipeline) -> pipeline.getApiReport server: server

    artEryPipelineDefaultHandler: ({url}, plainObjectRequest) =>
      if url.match @defaultHandlerRegex ||= /// ^ (\/ | | \/ #{ArtEry.config.apiRoot} .*) $ ///
        status: if url.match @exactDefaultHandlerRegex ||= /// ^ (\/ | | \/ #{ArtEry.config.apiRoot} \/? ) $ ///
            "success"
          else
            "missing"
        data: @getArtEryPipelineApiInfo()

    @getter
      promiseHttp: ->
        @_promiseHttp ||= new PromiseHttp merge @options,
          verbose: ArtEry.config.verbose
          port: @port
          name: "Art.Ery.Server"
          commonResponseHeaders: "Access-Control-Allow-Origin": "*"
          apiHandlers: [
            @artEryPipelineApiHandler
            @artEryPipelineDefaultHandler
          ]

      middleware: -> @promiseHttp.middleware

    start: ->
      unless 0 < objectKeyCount pipelines
        log.error """
          WARNING: there are 0 pipelines loaded; this server won't do much :).

          Please require your pipelines before starting the server.
          """

      startSingleServer = => @promiseHttp.start
        static: @options.static

      {numWorkers} = @
      {verbose} = ArtEry.config
      if verbose
        log "Art.Ery.Server":
          env: object process.env, when: (v, k) -> k.match /^art/
          versions: Neptune.getVersions()

      if numWorkers > 1
        log "Art.Ery.Server": throng: workers: numWorkers
        throng
          start:    startSingleServer
          workers:  numWorkers
          lifetime: Infinity
      else
        startSingleServer()