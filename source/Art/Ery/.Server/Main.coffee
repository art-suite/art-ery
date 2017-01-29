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
{pipelines, Request} = require '../'
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

    @findPipelineForRequest: ({url, method}) ->
      for pipelineName, pipeline of pipelines
        if match = url.match pipeline.restPathRegex
          [__, type, key] = match
          type ||= httpMethodsToArtEryRequestTypes[method.toLocaleLowerCase()]
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
    signSession: signSession = (requestData, responseData) ->
      {session} = responseData
      if session
        PromiseJsonWebToken.sign(
          objectWithout session || requestData.session || {}, "exp"
          privateSessionKey
          expiresIn: "30 days"
        )
        .then (signature) -> merge responseData, session: merge session, {signature}
      else
        responseData

    ###
    IN: plainObjectsRequest:
      session:         # encrypted session string
      query: session:  # encrypted session string
    OUT: (promise) verified session or {} if not valid
    ###
    verifySession: verifySession = (session) ->
      unless sessionSignature = session
        Promise.resolve({})
      else
        PromiseJsonWebToken.verify sessionSignature, privateSessionKey
        .then (session) -> session
        .catch (e)->
          log.error "session failed validation"
          {}

    artEryPipelineApiHandler: (request, requestData) ->
      if found = Main.findPipelineForRequest request
        verifySession requestData.session
        .then (session) ->
          {pipeline, type, key} = found
          pipeline._processRequest Request.createFromRemoteRequestProps {session, pipeline, type, key, requestData}

          .then ({plainObjectsResponse}) ->
            signSession requestData, plainObjectsResponse

    getArtEryPipelineApiInfo: ->
      {server, port} = @
      server ||= "http://localhost"
      server += ":#{port}" if port

      "Art.Ery.pipeline.json.rest.api":
        object pipelines, (pipeline) -> pipeline.getApiReport server: server

    allowAllCorsPreflightHandler: ({method, headers}) =>
      log {method, headers}
      method == "OPTIONS" &&
        status: "success"
        headers:
          "Access-Control-Allow-Origin": "*"
          "Access-Control-Allow-Methods": "GET, POST, PUT, UPDATE, DELETE"
          "Access-Control-Allow-Headers": ""
          "Content-Type": "text/html; charset=utf-8"

    artEryPipelineDefaultHandler: ({url}, plainObjectRequest) =>
      if url.match @defaultHandlerRegex ||= /// ^ (\/ #{ArtEry.config.apiRoot} .*) $ ///
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

          apiHandlers: [
            @artEryPipelineApiHandler
            @artEryPipelineDefaultHandler
          ]

          # CORS: allow absolutely everything!
          # This is ONLY safe because we don't use cookies, ever:
          #   Our session information is passed as normal data, and is stored in localStorage.
          commonResponseHeaders: "Access-Control-Allow-Origin": "*"
          handlers: [@allowAllCorsPreflightHandler]

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