{
  each
  present, Promise, BaseObject, RestClient, merge,
  inspect, isString, isObject, log, Validator,
  CommunicationStatus, arrayWith, w
  objectKeyCount, isString, isPlainObject
  objectWithout
} = Foundation = require 'art-foundation'
ArtEry = require './namespace'
{success, missing, failure, validStatus} = CommunicationStatus

# validator must be initialized after Request and Pipeline have bene defined
_validator = null
requestConstructorValidator = ->
  _validator ||= new Validator
    pipeline:           required: instanceof: ArtEry.Pipeline
    type:               required: fieldType: "string"
    session:            required: fieldType: "object"
    parentRequest:      instanceof: ArtEry.Request
    rootRequest:        instanceof: ArtEry.Request
    originatedOnServer: "boolean"
    props:              "object"
    key:                "string"

###
new Request(options)

IN: options:
  see requestConstructorValidator for the validated options
  below are special-case options

  # aliases
  data: >> @props.data
  key:  >> @props.key

  NOTE: Request doesn't care about @data, the alias is proved only as a convenience
  NOTE: Request only cares about @key for two things:
    - REST urls
    - cachedGet
    Otherwise, ArtEry.Request doesn't care

###
module.exports = class Request extends require './RequestResponseBase'

  constructor: (options) ->
    super
    requestConstructorValidator().preCreateSync options, context: "Art.Ery.Request options", logErrors: true
    {@type, @pipeline, @session, @parentRequest, @rootRequest = @, @originatedOnServer, @props = {}} = options

    @_props.key  = options.key  if options.key?
    @_props.data = options.data if options.data?

    @rootRequest ||= @
    @_subrequestCount = 0
    @_requestCache = null

  @property "type pipeline session originatedOnServer rootRequest parentRequest props data key"

  @getter
    key:  -> @_props.key
    data: -> @_props.data
    requestOptions: -> throw new Error "DEPRICATED: use props.requestOptions"

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

  @getter "subrequestCount",
    request: -> @
    shortInspect: ->
      "#{if @parentRequest then @parentRequest.shortInspect + ":" else ""}#{@pipeline.getName()}-#{@type}(#{@key})"

    requestCache: -> @rootRequest._requestCache ||= {}

    # Also implemented in Response
    beforeFilterLog:  -> @filterLog || []
    afterFilterLog:   -> []
    isSuccessful:     -> true
    notSuccessful:    -> false
    isRequest:        -> true
    requestPipelineAndType: -> "#{@pipeline.name}-#{@type}"

    propsForClone: ->
      {
        @pipeline
        @type
        @props
        @session
        @parentRequest
        @filterLog
        @originatedOnServer
        @subrequestCount
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

  @getter
    remoteRequestProps: ->
      {session, props, pipeline, type, key} = @
      requestData = null

      each props,
        when: (v, k) -> v != undefined && k != "key"
        with: (v, k) -> (requestData||={})[k] = v

      (requestData||={}).session = session.signature if session.signature

      getRestClientParamsForArtEryRequest
        restPath: pipeline.restPath
        server:   pipeline.remoteServer
        type:     type
        key:      key
        data:     requestData

  sendRemoteRequest: ->
    RestClient.restJsonRequest remoteRequest = @remoteRequestProps
    .catch ({info: {status, response}}) => merge response, {status}
    .then (remoteResponse)              => @_toResponse remoteResponse.status, merge remoteResponse, {remoteRequest, remoteResponse}
    .then (response) => response.handled "#{remoteRequest.method.toLocaleUpperCase()} #{remoteRequest.url}"
