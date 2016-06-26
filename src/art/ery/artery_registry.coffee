Foundation = require 'art-foundation'
{BaseObject} = Foundation

Artery = require './artery'

module.exports = class ArteryRegistry extends BaseObject
  @singletonClass()
  @getTable: (tableName) -> @singleton.getTable tableName

  constructor: ->
    @_tables = {}

  getTable: (tableName) ->
    @_tables[talleName] ||= new Artery tableName
