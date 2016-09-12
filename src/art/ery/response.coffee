Foundation = require 'art-foundation'
Request = require './Request'
{BaseObject, inspect, isPlainObject, log, CommunicationStatus, Validator, merge, isJsonType, formattedInspect} = Foundation
{success, missing, failure} = CommunicationStatus

failureValidator = new Validator
  request:  required: instanceof: Request
  status:   required: "communicationStatus"
  error:    required: true, validate: (a) -> a == undefined || isJsonType a

successValidator = new Validator
  request:  required: instanceof: Request
  status:   required: "communicationStatus"
  data:     validate: (a) -> a == undefined || isJsonType a
  session:  "object"

module.exports = class Response extends require './ArtEryBaseObject'
  constructor: (options) ->
    @_validateConstructorOptions options
    {@request, @status, @data, @session, @error} = options

  _validateConstructorOptions: (options)->
    if options.status == success
      successValidator.preCreateSync options, context: "success-Response options"
    else
      failureValidator.preCreateSync options, context: "failure-Response options"

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
  @property "request status data session error"
  @getter
    message: -> @data?.message || @error?.message
    isSuccessful: -> @_status == success
    inspectedObjects: ->
      [
        @class.namespacePath
        @props
      ]
    props: ->
      request: @request
      status: @status
      data: @data
      session: @session
      error: @error

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
        console.error "ArtEry.toResponse data is already a failing response object: #{formattedInspect e}"
        e
      else
        console.error "ArtEry.toResponse error: #{formattedInspect e}"
        new Response request: request, status: failure, error: error: e, message: e.toString()
    .then =>
      throw "request required" unless request
      if data instanceof Error
        console.error "ArtEry.toResponse data was Error: #{formattedInspect data}", data.stack
        throw data

      if isFailure
        console.error "ArtEry.toResponse #{formattedInspect request: request, status: failure, error: data}"
        new Response request: request, status: failure, error: data
      else if data?
        if data instanceof Response
          data
        else
          new Response request: request, status: success, data: data
      else
        new Response request: request, status: missing, error: data || message: "missing data for key: #{inspect request.key}"
