{
    BaseObject, CommunicationStatus, log, arrayWith
    defineModule, merge, isJsonType, isString, isPlainObject, inspect
} = require 'art-foundation'
ArtEry = require './namespace'
ArtEryBaseObject = require './ArtEryBaseObject'
{success, missing, failure} = CommunicationStatus

defineModule module, class RequestResponseBase extends ArtEryBaseObject

  constructor: (options) ->
    super
    {@filterLog} = options

  @property "filterLog"

  addFilterLog: (filter) -> @_filterLog = arrayWith @_filterLog, filter

  @getter
    inspectedObjects: ->
      [
        @class.namespacePath
        @props
      ]

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new @class merge @props, data: resolvedData

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withMergedData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new @class merge @props, data: merge @data, resolvedData


  next: (data, status = success) ->
    Promise.resolve data
    .then (data) =>
      # log next: data
      responseProps = if !data
        status = missing
        data: message: "missing responseProps for key: #{inspect @key}"
      else if isJsonType data
        data: data
      else
        data

      @_toResponse status, responseProps

  success: (responseProps) ->
    log RequestResponseBase: success: responseProps
    @_toResponse success, responseProps
  missing: (responseProps) -> @_toResponse missing, responseProps
  failure: (responseProps) -> @_toResponse failure, responseProps

  ###
  IN:
    responseProps: (optionally Promise returning:)
      object passed into Response constructor
      OR instanceof RequestResponseBase
      OR anything else:
        considered internal error, but it will create a valid, failing Response object
  OUT:
    promise.then (successful Response instance) ->
    .catch (unsuccessful Response instance) ->
  ###
  _toResponse: (status, responseProps) ->
    Promise.resolve responseProps
    .catch (e) =>
      status = failure
      e
    .then (responseProps) =>
      return responseProps if responseProps instanceof RequestResponseBase

      unless isPlainObject responseProps
        status = failure
        message = null
        responseProps = data: message: if responseProps instanceof Error
          log.error responseProps
          log.error "Internal Error: _toResponse received Error instance"
        else
          log.error "Internal Error: _toResponse exepecting responseProps or error", responseProps

      new ArtEry.Response merge
        request:  @request
        status:   status
        responseProps
