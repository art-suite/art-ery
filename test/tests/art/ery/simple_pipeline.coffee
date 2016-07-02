Foundation = require 'art-foundation'
Ery = require 'art-ery'

{merge, log} = Foundation
{Pipeline, Filter} = Ery

class SimpleFinalFilter extends Filter

  constructor: ->
    super
    @_store = {}
    @_nextUniqueKey = 0

  @getter
    nextUniqueKey: ->
      @_nextUniqueKey++ while @_store[@_nextUniqueKey]
      (@_nextUniqueKey++).toString()

  @before
    get: ({key}) ->
      @_store[key]

    create: (request) ->
      {nextUniqueKey} = @
      @_store[nextUniqueKey] = merge request.data, key: nextUniqueKey

    update: ({key, data}) ->
      if previousData = @_store[key]
        @_store[key] = merge previousData, data

    delete: ({key}) ->
      if previousData = @_store[key]
        @_store[key] = null
        previousData

module.exports = class SimplePipeline extends Pipeline
  @filter SimpleFinalFilter
