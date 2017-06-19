{
  each
  present, Promise, BaseObject, RestClient, merge,
  inspect, isString, isObject, log, Validator,
  CommunicationStatus, arrayWith, w
  objectKeyCount, isString, isPlainObject
  objectWithout
  isFunction
  object
  objectHasKeys
} = Foundation = require 'art-foundation'
ArtEry = require './namespace'
{success, missing, validStatus} = CommunicationStatus

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

CONCEPTS

  context:

    This is the only mutable part of the request. It establishes one shared context for
    a request, all its clones, subrequests, responses and response clones.

    The primary purpose is for subrequests to coordinate their actions with the primary
    request. Currently this is only used server-side.

    There are two contexts when using a remote server: The client-side context is not
    shared with the server-side context. A new context is created server-side when
    responding to the request.

    BUT - there is only one context if location == "both" - if we are running without
    a remote server.
###
module.exports = class Request extends require './RequestResponseBase'

  constructor: (options) ->
    super
    {@type, @pipeline, @session, @parentRequest, @originatedOnServer, @props = {}, @context = {}} = options

    key = @_props.key || options.key
    options.key = @_props.key = @pipeline.toKeyString key if key?

    requestConstructorValidator().preCreateSync options, context: "Art.Ery.Request options", logErrors: true

    throw new Error "options.requestOptions is DEPRICATED - use options.props" if options.requestOptions

    @_props.key  = options.key  if options.key?
    @_props.data = options.data if options.data?

  @property "type pipeline session originatedOnServer parentRequest props data key context"

  @getter
    key:            -> @_props.key
    data:           -> @_props.data
    requestData:    -> @_props.data
    requestProps:   -> @_props
    requestOptions: -> throw new Error "DEPRICATED: use props"

  ##############################
  # MISC
  ##############################
  @getter "subrequestCount",
    request:      -> @
    shortInspect: ->
      "#{if @parentRequest then @parentRequest.shortInspect + " > " else ""}#{@pipeline.getName()}-#{@type}(#{@key || ''})"

    # Also implemented in Response
    beforeFilterLog:  -> @filterLog || []
    afterFilterLog:   -> []
    isSuccessful:     -> true
    notSuccessful:    -> false
    isRequest:        -> true
    isRootRequest:    -> !@parentRequest
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
        @context
      }

    urlKeyClause: -> if present @key then "/#{@key}" else ""

  handled: (_handledBy) ->
    @success().then (response) -> response.handled _handledBy

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
      {session, data, props, pipeline, type, key} = @

      propsCount = 0
      props = object props, when: (v, k) -> v != undefined && k != "key" && k != "data"
      data  = object data,  when: (v) -> v != undefined

      remoteRequestData = null
      (remoteRequestData||={}).session = session.signature if session.signature
      (remoteRequestData||={}).props   = props if 0 < objectHasKeys props
      (remoteRequestData||={}).data    = data  if 0 < objectHasKeys data

      getRestClientParamsForArtEryRequest
        restPath: pipeline.restPath
        server:   if pipeline.remoteServer == true then "" else pipeline.remoteServer
        type:     type
        key:      key
        data:     remoteRequestData

  @createFromRemoteRequestProps: (options) ->
    {session, pipeline, type, key, requestData} = options
    {data, props} = requestData
    new Request {
      pipeline
      type
      session
      key
      data
      props
      originatedOnClient: true
    }

  sendRemoteRequest: ->
    RestClient.restJsonRequest remoteRequest = @remoteRequestProps
    .catch ({info: {status, response}}) => merge response, {status}
    .then (remoteResponse)              => @toResponse remoteResponse.status, merge remoteResponse, {remoteRequest, remoteResponse}
    .then (response)                    => response.handled "#{remoteRequest.method.toLocaleUpperCase()} #{remoteRequest.url}"
