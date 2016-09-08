Foundation = require 'art-foundation'
Request = require './Request'
{BaseObject, inspect, isPlainObject, log, CommunicationStatus, Validator, merge} = Foundation
{success, missing, failure} = CommunicationStatus

failureValidator = new Validator
  request:  required: instanceof: Request
  status:   required: "communicationStatus"
  error:    required: "object"

successValidator = new Validator
  request:  required: instanceof: Request
  status:   required: "communicationStatus"
  data:     required: "object"
  session:  "object"

module.exports = class Response extends require './ArtEryBaseObject'
  constructor: (options) ->
    @validate options
    {@request, @status, @data, @session, @error} = options

  validate: (options)->
    if options.status == success
      successValidator.preCreateSync options
    else
      failureValidator.preCreateSync options

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
  @toResponse: (data, request, reject) ->
    Promise.resolve data
    .then =>
      throw "request required" unless request

      throw data if data instanceof Error
      if data instanceof Response
        data
      else if !reject && data?
        if isPlainObject data
          new Response request: request, status: success, data: data
        else
          new Response request: request, status: failure, error: message: "request returned invalid data: #{inspect data}"

      else
        new Response request: request, status: missing, error: data || message: "missing data for key: #{inspect request.key}"

    .then (response) =>
      if response.isSuccessful
        Promise.resolve response
      else
        Promise.reject response
    .catch (e) =>
      return Promise.reject e if e instanceof Response
      console.error e, e.stack
      new Response request: request, status: failure, error: error: data, message: data.toString()

