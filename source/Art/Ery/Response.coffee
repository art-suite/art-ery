Foundation = require 'art-foundation'
Request = require './Request'
{pureMerge, Promise, BaseObject, object, isPlainArray, objectKeyCount, arrayWith, inspect, ErrorWithInfo, isPlainObject, log, CommunicationStatus, Validator, merge, isJsonType, formattedInspect, w} = Foundation
{success, missing, failure} = CommunicationStatus

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
    responseValidator.preCreateSync options, context: "Art.Ery.Response options", logErrors: true
    {@request, @status, @props = {}, @session, @remoteRequest, @remoteResponse, @handledBy, @replaceSession} = options

    throw new Error "options.requestOptions is DEPRICATED - use options.props" if options.requestOptions

    @request._responseProps = @props = pureMerge @request.responseProps, @props

    @_props.data = options.data if options.data

    @session = merge @request.session, @session unless @replaceSession

  isResponse:     true
  toString: -> "ArtEry.Response(#{@type}: #{@status}): #{@message}"

  # OUT: @
  handled: (_handledBy) ->
    return @ unless @isSuccessful
    @handledBy = _handledBy
    @

  @property "request status props session replaceSession remoteResponse remoteRequest handledBy"
  @getter
    data:               -> @_props.data

    beforeFilterLog:    -> @request.filterLog || []
    afterFilterLog:     -> @filterLog || []
    isSuccessful:       -> @_status == success
    isMissing:          -> @_status == missing
    notSuccessful:      -> @_status != success
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
        @subrequestCount
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

  # Request pass-throughs
  @getter
    isRootResponse:     -> @request.isRootRequest
    key:                -> @request.key
    requestCache:       -> @request.rootRequest
    pipeline:           -> @request.pipeline
    rootRequest:        -> @request.rootRequest
    parentRequest:      -> @request.parentRequest
    type:               -> @request.type
    originatedOnServer: -> @request.originatedOnServer
    subrequestCount:    -> @request.subrequestCount

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
          promise.reject new ErrorWithInfo

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
    else  Promise.reject  new ErrorWithInfo "#{@pipeline.getName()}.#{@type} request status: #{@status}, data: #{@data?.message || formattedInspect @data}", response: @
