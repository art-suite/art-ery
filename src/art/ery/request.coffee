Foundation = require 'art-foundation'
{BaseObject, merge, inspect, isString, isObject, log, Validator} = Foundation

validator = new Validator
  type:     type: "string", required: true
  pipeline: instanceof: Neptune.Art.Ery.Pipeline, required: true
  session:  type: "object", required: true
  data:     type: "object"
  key:      "id"

module.exports = class Request extends BaseObject
  constructor: (options) ->
    validator.preCreateSync options
    @_type      = options.type
    @_key       = options.key
    @_pipeline  = options.pipeline
    @_session   = options.session
    @_data      = options.data

  @getter "type key pipeline session data"

  @getter
    inspectObjects: ->
      [
        {inspect: => @class.namespacePath}
        @props
      ]
    props: ->
      type:   @type
      key:      @key
      pipeline:   @pipeline
      session:  @session
      data:     @data

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
      new Request log merge @props, data: merge @data, resolvedData
