Foundation = require 'art-foundation'
{present, BaseObject, RestClient, merge, inspect, isString, isObject, log, Validator, CommunicationStatus, arrayWith, w} = Foundation
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
    {@type, @key, @pipeline, @session, @data, @originatedOnServer, @originatedOnClient} = options

  @property "type key pipeline session data originatedOnServer"

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
        session:  @session
        data:     @data

    # log sendRemoteRequest: remoteRequestOptions

    RestClient.restJsonRequest remoteRequestOptions
    .catch (error) =>
      log.error ArtEry:Rquest:sendRemoteRequestError: error
      @failure error: error
    .then (remoteResponseOptions) =>
      log sendRemoteRequestSuccess:
        requestOptions: remoteRequestOptions
        remoteResponseOptions: remoteResponseOptions
      {data, status, filterLog, session} = remoteResponseOptions
      @_toResponse status,
        data: data
        filterLog: filterLog
        session: session
        remoteRequest: remoteRequestOptions
        remoteResponse: remoteResponseOptions
