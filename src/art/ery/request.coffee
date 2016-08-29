Foundation = require 'art-foundation'
{BaseObject, merge, inspect, isString, isObject, log, Validator, CommunicationStatus} = Foundation
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
    validator.preCreateSync options
    @_type      = options.type
    @_key       = options.key
    @_pipeline  = options.pipeline
    @_session   = options.session
    @_data      = options.data

  @getter "type key pipeline session data"

  @getter
    inspectedObjects: ->
      [
        @class.namespacePath
        @props
      ]
    props: ->
      pipeline: @pipeline
      type:     @type
      key:      @key
      session:  @session
      data:     @data

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new Request merge @props, data: resolvedData

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


  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withMergedData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new Request merge @props, data: merge @data, resolvedData
