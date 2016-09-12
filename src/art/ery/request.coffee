Foundation = require 'art-foundation'
{BaseObject, merge, inspect, isString, isObject, log, Validator, CommunicationStatus, arrayWith} = Foundation
ArtEry = require './namespace'
{success, missing, failure, validStatus} = CommunicationStatus

validator = new Validator
  type:     required: "string"
  pipeline: required: instanceof: Neptune.Art.Ery.Pipeline
  session:  required: "object"
  data:     "object"
  key:      "string"

module.exports = class Request extends require './ArtEryBaseObject'
  constructor: (options) ->
    validator.preCreateSync options, context: "Request options"
    {@type, @key, @pipeline, @session, @data, @beforeFilterLog} = options

  addBeforeFilterLog: (filter) -> @_beforeFilterLog = arrayWith @_beforeFilterLog, filter

  @property "type key pipeline session data beforeFilterLog"

  @getter
    inspectedObjects: ->
      [
        @class.namespacePath
        @props
      ]
    beforeFilterLog: -> @_beforeFilterLog || []
    filterLog: ->
      [before..., handler] = @beforeFilterLog
      before: before
      handler: handler

    props: ->
      pipeline:        @pipeline
      type:            @type
      key:             @key
      session:         @session
      data:            @data
      beforeFilterLog: @beforeFilterLog

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new Request merge @props, data: resolvedData

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withMergedData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new Request merge @props, data: merge @data, resolvedData

  # return a new success-Response
  success: (responseProps) ->
    new ArtEry.Response merge responseProps,
      status: success
      data: responseProps.data || {}
      request: @

  # return a new failure-Response
  failure: (responseProps) ->
    new ArtEry.Response merge responseProps,
      status: failure
      error: if isString responseProps.error
          message: responseProps.error
        else
          responseProps.error
      request: @

  # return a new missing-Response
  missing: (responseProps) ->
    new ArtEry.Response merge responseProps,
      status: missing
      request: @
