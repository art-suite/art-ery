Foundation = require 'art-foundation'
Request = require './Request'
{BaseObject, arrayWith, inspect, isPlainObject, log, CommunicationStatus, Validator, merge, isJsonType, formattedInspect} = Foundation
{success, missing, failure} = CommunicationStatus

responseValidator = new Validator
  request:  required: instanceof: Request
  status:   required: "communicationStatus"
  data:     validate: (a) -> a == undefined || isJsonType a
  session:  "object"

module.exports = class Response extends require './ArtEryBaseObject'
  constructor: (options) ->
    @_validateConstructorOptions options
    {@request, @status, @data, @session, @error, @afterFilterLog} = options

  addAfterFilterLog: (filter) -> @_afterFilterLog = arrayWith @_afterFilterLog, filter

  _validateConstructorOptions: (options)->
    responseValidator.preCreateSync options, context: "response options"

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new Response merge @props, data: resolvedData

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withMergedData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new Response merge @props, data: merge @data, resolvedData

  toString: -> "ArtEry.Response(#{@_status}): #{@message}"
  @property "request status data session error afterFilterLog"
  @getter
    beforeFilterLog: -> @request.beforeFilterLog
    afterFilterLog: -> @_afterFilterLog || []
    filterLog: ->
      merge @request.filterLog,
        after:  @afterFilterLog
    message: -> @data?.message
    isSuccessful: -> @_status == success
    inspectedObjects: ->
      [
        @class.namespacePath
        @props
      ]
    props: ->
      request:        @request
      status:         @status
      data:           @data
      session:        @session
      afterFilterLog: @afterFilterLog

  ###
  OUT:
    promise.then (successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  @toResponse: (data, request, isFailure) ->
    Promise.resolve data
    .then (_data) -> data = _data
    .catch (e) =>
      Promise.reject if e instanceof Response
        log.error "ArtEry.toResponse data is already a failing response object: #{formattedInspect e}"
        e
      else
        log.error "ArtEry.toResponse error:", e
        new Response request: request, status: failure, data: error: e, message: e.toString()
    .then =>
      throw "request required" unless request
      if data instanceof Error
        log.error "ArtEry.toResponse data was Error: #{formattedInspect data}", data.stack
        throw data

      if isFailure
        log.error "ArtEry.toResponse", status: failure, request: request, data: data
        new Response request: request, status: failure, data: data
      else if data?
        if data instanceof Response
          data
        else
          new Response request: request, status: success, data: data
      else
        new Response request: request, status: missing, data: data || message: "missing data for key: #{inspect request.key}"
