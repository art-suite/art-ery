{defineModule, isPlainObject, log, BaseObject, formattedInspect, isString, isFunction} = require 'art-foundation'
# KeyFieldsMixin = require './KeyFieldsMixin'
# TODO - add KeyFieldsMixin
# PURPOSE: allow multi-key queries to be defined using KeyFieldsMixin's
#   awesome implementation: @primaryKey 'topicId/postOrder'
#   The problem is KeyFieldsMixin's configuration is 100% at the class level,
#   but here, every instance of PipelineQuery needs it's own key-fields config.
#   It needs to be initializable in the instance and via the constructor, hopefully
#   via setters so we don't need to touch the constructor below.
#   A valid query declaration could be: query: (->), primareyKey: 'topicId/PostOrder'
#   And that's it. Art.Ery request keys would look like: {topicId, postOrder}
# STRATEGY: Can we just use @extendableProperty?
#   Do we need the ES6 extendableProperty?
#     I don't think so. The new ES5 extendableProperty defines a setter-extended for instacnes.
#     It just isn't available at the class-level yet, but that's OK for this purpose.
# PROBLEM: There is one further problem, query-request are attached to the singleton pipeline,
#   and key encoding is declared for all requests in the singleton pipeline in the pipeline's class.
#   Clearly we'd need to override key encoding for specific query-request types. Should be doable...
defineModule module, class PipelineQuery extends BaseObject

  constructor: (@queryName, @options) ->
    @options = query: @options if isFunction @options
    @[k] = v for k, v of @options
    throw new Error "query handler-function with at least one argument required. options: #{formattedInspect options}" unless isFunction(@query) && @query.length > 0

  @getter name: -> @queryName

  toKeyString: (v) ->
    return null unless v?
    if isPlainObject(v) && @dataToKeyString
      @dataToKeyString v
    else if isString v then v
    else throw new Error "PipelineQuery: invalid key: #{formattedInspect v}"