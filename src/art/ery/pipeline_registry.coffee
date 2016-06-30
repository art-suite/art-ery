Foundation = require 'art-foundation'
{BaseObject} = Foundation

Pipeline = require './pipeline'

module.exports = class PipelineRegistry extends BaseObject
  @singletonClass()
  @getTable: (tableName) -> @singleton.getTable tableName

  constructor: ->
    @_tables = {}

  getTable: (tableName) ->
    @_tables[talleName] ||= new Pipeline tableName
