{present, Promimse, BaseObject, RestClient, merge, inspect, isString, isObject, log, Validator, CommunicationStatus, arrayWith, w
objectKeyCount} = Foundation = require 'art-foundation'
ArtEry = require './namespace'
{success, missing, failure, validStatus} = CommunicationStatus

validator = new Validator
  type:               w "required string"
  pipeline:           required: instanceof: Neptune.Art.Ery.Pipeline
  session:            w "required object"
  data:               "object"
  key:                "string"
  originatedOnServer: "boolean"

module.exports = class Request extends require './RequestResponseBase'
  constructor: (options) ->
    super
    validator.preCreateSync options, context: "Art.Ery.Request options", logErrors: true
    {@type, @key, @pipeline, @session, @data, @originatedOnServer, @originatedOnClient} = options

  @property "type key pipeline session data originatedOnServer originatedOnClient"

  toString: -> "ArtEry.Request(#{@type} key: #{@key}, hasData: #{!!@data})"

  ###
  OUT:
    Success: promise.then -> request
    Failure: promise.then -> failing response

  Success if @originatedOnServer is true
  ###
  requireServerOrigin: (message) ->
    if @originatedOnServer
      Promise.resolve @
    else
      @failure data: message: "#{@requestPipelineAndType}: originatedOnServer required #{message || ""}"

  ###
  OUT:
    Success: promise.then -> request
    Failure: promise.then -> failing response

  Success if either testResult or @originatedOnServer are true.
  ###
  requireServerOriginOr: (testResult, message) ->
    if testResult || @originatedOnServer
      Promise.resolve @
    else
      @failure data: message: "#{@requestPipelineAndType}: originatedOnServer required #{message || ""}"

  @getter
    request: -> @

    # Also implemented in Response
    beforeFilterLog:  -> @filterLog || []
    afterFilterLog:   -> []
    isSuccessful:     -> true
    notSuccessful:    -> false
    isRequest:        -> true
    requestPipelineAndType: -> "#{@pipeline.name}-#{@type}"

    props: ->
      {
        @pipeline
        @type
        @key
        @session
        @data
        @filterLog
        @originatedOnServer
        @originatedOnClient
      }

    urlKeyClause: -> if present @key then "/#{@key}" else ""

  getRestRequestUrl:    (server) -> "#{server}/#{@pipeline.name}#{@urlKeyClause}"
  getNonRestRequestUrl: (server) -> "#{server}/#{@pipeline.name}-#{@type}#{@urlKeyClause}"

  restMap =
    get:    "get"
    create: "post"
    update: "put"
    delete: "delete"

  @getRestClientParamsForArtEryRequest: getRestClientParamsForArtEryRequest = ({server, restPath, type, key, data}) ->
    urlKeyClause = if present key then "/#{key}" else ""
    server ||= ""

    url = if method = restMap[type]
      "#{server}#{restPath}#{urlKeyClause}"
    else
      method = "post"
      "#{server}#{restPath}-#{type}#{urlKeyClause}"

    method: method
    url:    url
    data:   data

  sendRemoteRequest: ->
    requestData = null
    (requestData||={}).data = @data if @data && objectKeyCount(@data) > 0
    (requestData||={}).session = @session.signature if @session.signature

    remoteRequest = getRestClientParamsForArtEryRequest
      restPath: @pipeline.restPath
      server:   @pipeline.remoteServer
      type:     @type
      key:      @key
      data:     requestData

    RestClient.restJsonRequest remoteRequest
    .catch ({info: {status, response}}) => merge response, {status}
    .then (remoteResponse)              => @_toResponse remoteResponse.status, merge remoteResponse, {remoteRequest, remoteResponse}
    .then (response) => response.handled "#{remoteRequest.method.toLocaleUpperCase()} #{remoteRequest.url}"
