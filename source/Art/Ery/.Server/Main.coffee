throng  = require 'throng'
require 'colors'

{
  eq
  BaseObject
  select, objectWithout, object, objectKeyCount, log, defineModule, merge, CommunicationStatus, isNumber
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

    iatAgeInDays = (iat) -> (Date.now() / 1000 - iat) / (60 * 60 * 24)

    shouldReturnNewSignedSession: shouldReturnNewSignedSession = (oldSession, newSession) ->
      {iat, exp} = oldSession if oldSession
      newSession && (             # we have a new session AND
        !iat ||                     # the last session wasn't signed
        iatAgeInDays(iat) > 1 ||    # OR the session is more than 1 day old
        !eq oldSession, newSession  # OR the session changed
      )

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
    signSession: signSession = (oldSession, responseData) ->

      if shouldReturnNewSignedSession oldSession, newSession = responseData.session || oldSession
        PromiseJsonWebToken.sign(
          objectWithout newSession, "exp", "iat"
          privateSessionKey
          expiresIn: "30 days"
        )
        .then (signature) -> merge responseData, session: merge newSession, {signature}
      else
        objectWithout responseData, "session"

    ###
    IN: plainObjectsRequest:
      session:         # encrypted session string
      query: session:  # encrypted session string
    OUT:
      promise.then (verifiedSession) ->
      promise.catch -> # session was invalid
    ###
    verifySession: verifySession = (session) ->
      unless sessionSignature = session
        Promise.resolve({})
      else
        PromiseJsonWebToken.verify sessionSignature, privateSessionKey
        .then (session) -> session

    artEryPipelineApiHandler: (request, requestData) ->
      if found = Main.findPipelineForRequest request
        {pipeline, type, key} = found
        processRequest = (session) ->
          pipeline._processRequest Request.createFromRemoteRequestProps {session, pipeline, type, key, requestData}
          .then ({plainObjectsResponse}) -> signSession session, plainObjectsResponse

        verifySession requestData.session
        .then processRequest
        .catch ->
          processRequest {}
          .then (plainObjectsResponseWithSignedSession) ->
            merge plainObjectsResponseWithSignedSession, replaceSession: true

    getArtEryPipelineApiInfo: ->
      {server, port} = @
      server ||= "http://localhost"
      server += ":#{port}" if port

      "Art.Ery.pipeline.json.rest.api":
        object pipelines, (pipeline) -> pipeline.getApiReport server: server

    allowAllCorsPreflightHandler: ({method, headers}) =>
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