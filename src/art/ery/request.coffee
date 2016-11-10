{present, BaseObject, RestClient, merge, inspect, isString, isObject, log, Validator, CommunicationStatus, arrayWith, w
} = Foundation = require 'art-foundation'
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
    validator.preCreateSync options, context: "Request options"
    {@type, @key, @pipeline, @session, @data, @originatedOnServer, @originatedOnClient, @sessionSignature} = options

  @property "type key pipeline session data originatedOnServer sessionSignature originatedOnClient"

  toString: -> "ArtEry.Request(#{@type} key: #{@key}, hasData: #{!!@data})"

  requireServerOrigin: (message = "(no further explanation)")->
    unless @originatedOnServer
      throw @failure data: message: "#{@type}-request: originatedOnServer required #{message || ""}"
    @

  @getter
    request: -> @

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
    remoteRequestOptions = getRestClientParamsForArtEryRequest
      restPath: @pipeline.restPath
      server:   @pipeline.remoteServer
      type:     @type
      key:      @key
      data:
        data:             @data
        session:          @session
        sessionSignature: @sessionSignature

    RestClient.restJsonRequest remoteRequestOptions
    .catch (error) =>
      log sendRemoteRequest: error: error
      if CommunicationStatus[error.response.status]
        # pass it through to the normal handler
        error.response
      else
        @failure error: error
    .then (remoteResponseOptions) =>
      {data, status, filterLog, session, sessionSignature} = remoteResponseOptions
      @_toResponse status,
        data: data
        filterLog: filterLog
        session: session
        sessionSignature: sessionSignature
        remoteRequest: remoteRequestOptions
        remoteResponse: remoteResponseOptions
      .then (response) =>
        response.handled "#{remoteRequestOptions.method.toLocaleUpperCase()} #{remoteRequestOptions.url}"