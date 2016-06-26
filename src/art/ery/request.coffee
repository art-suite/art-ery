Foundation = require 'art-foundation'
{BaseObject} = Foundation

module.exports = class Request extends BaseObject
  constructor: (@_key, @_table, @_data, @_session) ->

  @getter "key, artery, data, session",
    inspectObjects: ->
      [
        {inspect: => @class.namespacePath}
        key: @key, artery: @artery, data: @data, session: @session
      ]
