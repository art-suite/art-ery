{
  each
  present, Promise, BaseObject, RestClient, merge,
  inspect, isString, isObject, log, Validator,
  CommunicationStatus, arrayWith, w
  objectKeyCount, isString, isPlainObject
  objectWithout
  isFunction
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

    In general, type: "get" and key: "string" is a CACHEABLE request.
    This is why it must be a string.
    Currently there are no controls for HOW cacheable type-get is, though.
    All other requests are NOT cacheable.
###
module.exports = class Request extends require './RequestResponseBase'

  constructor: (options) ->
    super
    options.key ||= options.props?.key # so the validator can check it
    requestConstructorValidator().preCreateSync options, context: "Art.Ery.Request options", logErrors: true
    {@type, @pipeline, @session, @parentRequest, @originatedOnServer, @props = {}} = options

    throw new Error "options.requestOptions is DEPRICATED - use options.props" if options.requestOptions

    @_props.key  = options.key  if options.key?
    @_props.data = options.data if options.data?

    @rootRequest = @parentRequest?.rootRequest || @
    @_subrequestCount = 0
    @_requestCache = null

  @property "type pipeline session originatedOnServer rootRequest parentRequest props data key"

  @getter
    key:  -> @_props.key
    data: -> @_props.data
    requestOptions: -> throw new Error "DEPRICATED: use props.requestOptions"

  toString: -> "ArtEry.Request(#{@type} key: #{@key}, hasData: #{!!@data})"

  ##############################
  # requirement helpers
  ##############################
  ###
  OUT:
    Success: promise.then -> request
    Failure: promise.then -> failing response

  Success if test is true
  ###
  require: (test, message) ->
    if test
      Promise.resolve @
    else
      message = message() if isFunction message
      @failure data: message: "#{@requestPipelineAndType}: requirement: #{message || ""}"

  ###
  Success if @originatedOnServer is true
  OUT: see require
  ###
  requireServerOrigin: (message) ->
    @requireServerOriginOr true, message

  ###
  Success if either testResult or @originatedOnServer are true.
  OUT: see require
  ###
  requireServerOriginOr: (testResult, message) ->
    @require testResult || @originatedOnServer, ->
      message = "to #{message}" unless message.match /\s*to\s/
      "originatedOnServer required #{message || ''}"

  ##############################
  # MISC
  ##############################
  @getter "subrequestCount",
    request: -> @
    shortInspect: ->
      "#{if @parentRequest then @parentRequest.shortInspect + " > " else ""}#{@pipeline.getName()}-#{@type}(#{@key || ''})"

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
