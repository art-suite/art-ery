Foundation = require 'art-foundation'
{BaseObject} = Foundation

Table = require './table'

module.exports = class TableRegistry extends BaseObject
  @singletonClass()
  @getTable: (tableName) -> @singleton.getTable tableName

  constructor: ->
    @_tables = {}

  getTable: (tableName) ->
    @_tables[talleName] ||= new Table tableName
