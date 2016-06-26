Foundation = require 'art-foundation'
Ery = require 'art-ery'

{merge, log} = Foundation
{Artery} = Ery

module.exports = class SimpleArtery extends Artery

  constructor: ->
    super
    @_store = {}
    @_nextUniqueKey = 0

  @getter
    nextUniqueKey: ->
      @_nextUniqueKey++ while @_store[@_nextUniqueKey]
      (@_nextUniqueKey++).toString()

  _processGet: (request) -> @_store[request.key]

  _processCreate: (request) ->
    {nextUniqueKey} = @
    @_store[nextUniqueKey] = merge request.data, key: nextUniqueKey

  _processUpdate: ({key, data}) ->
    if previousData = @_store[key]
      @_store[key] = merge previousData, data

  _processDelete: ({key}) ->
    if previousData = @_store[key]
      @_store[key] = null
      previousData
