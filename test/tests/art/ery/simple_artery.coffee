Foundation = require 'art-foundation'
Ery = require 'art-ery'

{merge, log} = Foundation
{Pipeline, Handler} = Ery

class SimpleFinalHandler extends Handler

  constructor: ->
    super
    @_store = {}
    @_nextUniqueKey = 0

  @getter
    nextUniqueKey: ->
      @_nextUniqueKey++ while @_store[@_nextUniqueKey]
      (@_nextUniqueKey++).toString()

  beforeGet: (request) -> @_store[request.key]

  beforeCreate: (request) ->
    {nextUniqueKey} = @
    @_store[nextUniqueKey] = merge request.data, key: nextUniqueKey

  beforeUpdate: ({key, data}) ->
    if previousData = @_store[key]
      @_store[key] = merge previousData, data

  beforeDelete: ({key}) ->
    if previousData = @_store[key]
      @_store[key] = null
      previousData

module.exports = class SimpleArtery extends Pipeline
  constructor: ->
    super
    @addHandler new SimpleFinalHandler
