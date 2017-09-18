Foundation = require 'art-foundation'
Request = require './Request'
{pureMerge, Promise, BaseObject, object, isPlainArray, objectKeyCount, arrayWith, inspect, RequestError, isPlainObject, log, CommunicationStatus, Validator, merge, isJsonType, formattedInspect, w} = Foundation
{success, missing} = CommunicationStatus

responseValidator = new Validator
  request:  w "required", instanceof: Request
  status:   w "required communicationStatus"
  session:  "object"
  props:    "object"

###
TODO: Merge Response back into Request

  Turns out, Response has very little special functionality.
  At this point, the RequestuestResponseBase / Request / Response class structure
  actually requires more code than just one, Request class would.

What to add to Request:

  @writeOnceProperty "responseStatus responseSession responseProps"

  @getter
    hasResponse: -> !!@responseStatus

  Split out: filterLog into beforeFilterLog and afterFilterLog.
###
###
new Response

IN:
  request: Request (required)
  status: CommunicationStatus (required)
  props: plainObject with all JSON values
  session: plainObject with all JSON values

  data: JSON value
    data is an alias for @props.data
    EFFECT: replaces @props.data
    NOTE: for clientRequest, @props.data is the value returned unless returnResponseObject is requested

  remoteRequest: remoteResponse:
    Available for inspecting what exactly went over-the-wire.
    Otherwise ignored by Response

  handledBy:
    Available for inspecting what code actually handled the request.
    Otherwise ignored by Response

  replaceSession: false
    If true, then the current session will be replace instead of merged
    with the new one. If no new session is provided, the old session
    will be reset to empty.

    NOTE: Pipeline is responsible for updating the Client session
      from the response session returned after a request.

      Pipeline checks for @replaceSession to implement the above
      semantics.
###


module.exports = class Response extends require './RequestResponseBase'
  constructor: (options) ->
    super
    responseValidator.validate options, context: "Art.Ery.Response options", logErrors: true
    {@request, @status, @props = {}, @session, @remoteRequest, @remoteResponse, @handledBy, @replaceSession} = options

    throw new Error "options.requestOptions is DEPRICATED - use options.props" if options.requestOptions

    @_props.data = options.data if options.data

    @session ||= @request.session


    if @status != success
      @_captureErrorStack()

    @setGetCache() if @type == "create" || @type == "get"

  isResponse:     true

  # OUT: @
  handled: (_handledBy) ->
    return @ unless @isSuccessful
    @handledBy = _handledBy
    @

  @property "request status props session replaceSession remoteResponse remoteRequest handledBy"
  @getter
    data:               -> @_props.data
    responseData:       -> @_props.data
    responseProps:      -> @_props

    beforeFilterLog:    -> @request.filterLog || []
    afterFilterLog:     -> @filterLog || []
    isSuccessful:       -> @_status == success
    isMissing:          -> @_status == missing
    notSuccessful:      -> @_status != success
    description: -> "#{@requestString} response: #{@status}"
    propsForClone: ->
      {
        @request
        @status
        @props
        @session
        @filterLog
        @handledBy
        @remoteRequest
        @remoteResponse
      }
    propsForResponse: -> @propsForClone

    plainObjectsResponse: ->
      object {@status, @props, @session, @beforeFilterLog, @handledBy, @afterFilterLog},
        when: (v) ->
          switch
            when isPlainObject v then objectKeyCount(v) > 0
            when isPlainArray  v then v.length > 0
            else v != undefined

    # DEPRICATED
    # message:            -> @data?.message

  withMergedSession: (session) ->
    Promise.resolve(session).then (session) =>
      new @class merge @propsForClone, session: merge @session, session

  ###
  IN: options:
    returnNullIfMissing: true [default: false]
      if status == missing
        if returnNullIfMissing
          promise.resolve null
        else
          promise.reject new RequestError

    returnResponseObject: true [default: false]
      if true, the response object is returned, otherwise, just the data field is returned.

  OUT:
    # if response.isSuccessful && returnResponseObject == true
    promise.then (response) ->

    # if response.isSuccessful && returnResponseObject == false
    promise.then (data) ->

    # if response.isMissing && returnNullIfMissing == true
    promise.then (data) -> # data == null

    # else
    promise.catch (errorWithInfo) ->
      {response} = errorWithInfo.info

  ###
  toPromise: (options) ->
    {returnNullIfMissing, returnResponseObject} = options if options
    {data, isSuccessful, isMissing} = @

    if isMissing && returnNullIfMissing
      data = null
      isSuccessful = true

    if isSuccessful
      Promise.resolve if returnResponseObject then @ else data
    else Promise.reject @_getRejectionError()

  _getRejectionError: ->
    @_preparedRejectionError ||= new RequestError {
      sourceLib: "ArtEry " + @pipelineName
      @requestData
      @type
      @key
      @status
      @data
      response: @
    }

  ###
  EFFECT:
    If we create the RequestError when the error-response is created
    we are much more likely to capture the correct stack-trace for the
    events that lead to the error.

  TODO: We may only want to do this when artPromiseDebug=true or dev=true
  ###
  _captureErrorStack: -> @_getRejectionError()
