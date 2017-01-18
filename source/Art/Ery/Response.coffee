Foundation = require 'art-foundation'
Request = require './Request'
{Promise, BaseObject, objectKeyCount, arrayWith, inspect, ErrorWithInfo, isPlainObject, log, CommunicationStatus, Validator, merge, isJsonType, formattedInspect, w} = Foundation
{success, missing, failure} = CommunicationStatus

responseValidator = new Validator
  request:  w "required", instanceof: Request
  status:   w "required communicationStatus"
  data:     validate: (a) -> a == undefined || isJsonType a
  session:  "object"

module.exports = class Response extends require './RequestResponseBase'
  constructor: (options) ->
    super
    responseValidator.preCreateSync options, context: "Art.Ery.Response options", logErrors: true
    {@request, @status, @data = {}, @session, @error, @remoteRequest, @remoteResponse, @handledBy} = options
    @session ||= @request.session
    # log.error newResponse: @inspectedObjects

  isResponse: true
  toString: -> "ArtEry.Response(#{@type}: #{@status}): #{@message}"

  # OUT: @
  handled: (_handledBy) ->
    return @ unless @isSuccessful
    @handledBy = _handledBy
    @

  @property "request status data session error remoteResponse remoteRequest handledBy"
  @getter
    requestCache:     -> @request.rootRequest
    pipeline:         -> @request.pipeline
    rootRequest:      -> @request.rootRequest
    parentRequest:    -> @request.parentRequest
    type:             -> @request.type
    originatedOnServer: -> @request.originatedOnServer
    beforeFilterLog:  -> @request.filterLog || []
    afterFilterLog:   -> @filterLog || []
    message:          -> @data?.message
    isSuccessful:     -> @_status == success
    isMissing:        -> @_status == missing
    notSuccessful:    -> @_status != success
    subrequestCount:  -> @request.subrequestCount
    props: ->
      {
        @request
        @status
        @data
        @session
        @filterLog
        @handledBy
        @remoteRequest
        @remoteResponse
        @subrequestCount
      }
    propsForResponse: -> @props

    plainObjectsResponse: ->
      out = {@status, @data}
      out.session = @session if @session && objectKeyCount(@session) > 0
      out.beforeFilterLog = @beforeFilterLog if @beforeFilterLog?.length > 0
      out.handledBy = @handledBy
      out.afterFilterLog = @afterFilterLog if @afterFilterLog?.length > 0
      out

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
    else  Promise.reject  new ErrorWithInfo "#{@pipeline.getName()}.#{@type} request status: #{@status}", response: @
