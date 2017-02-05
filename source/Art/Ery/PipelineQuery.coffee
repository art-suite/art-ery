{defineModule, isPlainObject, log, BaseObject, formattedInspect, isString, isFunction} = require 'art-foundation'

defineModule module, class PipelineQuery extends BaseObject

  constructor: (@queryName, @options) ->
    @options = query: @options if isFunction @options
    @[k] = v for k, v of @options
    throw new Error "query handler-function with at least one argument required. options: #{formattedInspect options}" unless isFunction(@query) && @query.length > 0

  toKeyString: (v) ->
    return null unless v?
    if isPlainObject(v) && @dataToKeyString
      @dataToKeyString v
    else if isString v then v
    else throw new Error "PipelineQuery: invalid key: #{formattedInspect v}"