Foundation = require 'art-foundation'
Request = require './Request'
{Promise, BaseObject, object, isPlainArray, objectKeyCount, arrayWith, inspect, ErrorWithInfo, isPlainObject, log, CommunicationStatus, Validator, merge, isJsonType, formattedInspect, w} = Foundation
{success, missing, failure} = CommunicationStatus

responseValidator = new Validator
  request:  w "required", instanceof: Request
  status:   w "required communicationStatus"
  session:  "object"
  props:    "object"

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
###


module.exports = class Response extends require './RequestResponseBase'
  constructor: (options) ->
    super
    responseValidator.preCreateSync options, context: "Art.Ery.Response options", logErrors: true
    {@request, @status, @props = {}, @session, @remoteRequest, @remoteResponse, @handledBy} = options

    throw new Error "options.requestOptions is DEPRICATED - use options.props" if options.requestOptions

    @_props.data = options.data if options.data

    @session ||= @request.session

  isResponse: true
  toString: -> "ArtEry.Response(#{@type}: #{@status}): #{@message}"

  # OUT: @
  handled: (_handledBy) ->
    return @ unless @isSuccessful
    @handledBy = _handledBy
    @

  @property "request status props session remoteResponse remoteRequest handledBy"
  @getter
    data:               -> @_props.data
    key:                -> @request.key
    requestCache:       -> @request.rootRequest
    pipeline:           -> @request.pipeline
    rootRequest:        -> @request.rootRequest
    parentRequest:      -> @request.parentRequest
    type:               -> @request.type
    originatedOnServer: -> @request.originatedOnServer

    beforeFilterLog:    -> @request.filterLog || []
    afterFilterLog:     -> @filterLog || []
    message:            -> @data?.message
    isSuccessful:       -> @_status == success
    isMissing:          -> @_status == missing
    notSuccessful:      -> @_status != success
    subrequestCount:    -> @request.subrequestCount
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