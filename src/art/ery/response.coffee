Foundation = require 'art-foundation'
Request = require './Request'
{BaseObject, arrayWith, inspect, isPlainObject, log, CommunicationStatus, Validator, merge, isJsonType, formattedInspect, w} = Foundation
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
    {@request, @status, @data = {}, @session, @sessionSignature, @error, @remoteRequest, @remoteResponse} = options
    @session ||= @request.session
    # log newResponse: @inspectedObjects

  isResponse: true
  toString: -> "ArtEry.Response(#{@type}: #{@status}): #{@message}"

  @property "request status data session sessionSignature error remoteResponse remoteRequest"
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
        @remoteRequest
        @remoteResponse
      }

    plainObjectsResponse: ->
      out = {@status, @data, @session}
      out.filterLog = @filterLog if @filterLog?.length > 0
      out
