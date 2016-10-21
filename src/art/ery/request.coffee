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
      pipeline:             @pipeline
      type:                 @type
      key:                  @key
      session:              @session
      data:                 @data
      filterLog:            @filterLog
      originatedOnServer:   @originatedOnServer

    urlKeyClause: -> if present @key then "/#{@key}" else ""

  getRestRequestUrl:    (server) -> "#{server}/#{@pipeline.name}#{@urlKeyClause}"
  getNonRestRequestUrl: (server) -> "#{server}/#{@pipeline.name}-#{@type}#{@urlKeyClause}"

  restMap =
    get:    "get"
    create: "post"
    update: "put"
    delete: "delete"

  sendRemoteRequest: (server) ->
    url = if @type.match /^get|update|delete|create$/
      verb = restMap[@type]
      @getRestRequestUrl server
    else
      verb = "post"
      @getNonRestRequestUrl server

    log sendRemoteRequest: options =
      verb: verb
      url: url
      data: @data

    RestClient.restJsonRequest options
    .then ({data, status, filterLog, session}) =>
      log sendRemoteRequestSuccess:
        url: url
        status: status
        data: data
        filterLog: filterLog
        session: session
      @_toResponse success,
        data: data
        filterLog: filterLog
        session: session
    .catch (error) =>
      log.error ArtEry:Rquest:sendRemoteRequestError: error
      @failure error: error