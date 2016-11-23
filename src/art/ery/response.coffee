Foundation = require 'art-foundation'
Request = require './Request'
{BaseObject, objectKeyCount, arrayWith, inspect, isPlainObject, log, CommunicationStatus, Validator, merge, isJsonType, formattedInspect, w} = Foundation
{success, missing, failure} = CommunicationStatus

responseValidator = new Validator
  request:  w "required", instanceof: Request
  status:   w "required communicationStatus"
  data:     validate: (a) -> a == undefined || isJsonType a
  session:  "object"

module.exports = class Response extends require './RequestResponseBase'
  constructor: (options) ->
    super
    responseValidator.preCreateSync options, context: "Response options"
    {@request, @status, @data = {}, @session, @sessionSignature, @error, @remoteRequest, @remoteResponse, @handledBy} = options
    @session ||= @request.session
    # log newResponse: @inspectedObjects

  isResponse: true
  toString: -> "ArtEry.Response(#{@type}: #{@status}): #{@message}"

  # OUT: promise.then => @
  handled: (handledBy) ->
    @handledBy = handledBy if @status == success
    Promise.resolve @

  @property "request status data session sessionSignature error remoteResponse remoteRequest handledBy"
  @getter
    type:             -> @request.type
    originatedOnServer: -> @request.originatedOnServer
    beforeFilterLog:  -> @request.filterLog
    afterFilterLog:   -> @filterLog
    message:          -> @data?.message
    isSuccessful:     -> @_status == success
    notSuccessful:    -> @_status != success
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
      }

    plainObjectsResponse: ->
      out = {@status, @data}
      out.session = @session if @session && objectKeyCount(@session) > 0
      out.beforeFilterLog = @beforeFilterLog if @beforeFilterLog?.length > 0
      out.handledBy = @handledBy
      out.afterFilterLog = @afterFilterLog if @afterFilterLog?.length > 0
      out
