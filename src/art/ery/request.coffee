Foundation = require 'art-foundation'
{BaseObject, merge} = Foundation

module.exports = class Request extends BaseObject
  constructor: (@_key, @_table, @_data, @_session) ->

  @getter "key, artery, data, session",
    inspectObjects: ->
      [
        {inspect: => @class.namespacePath}
        key: @key, artery: @artery, data: @data, session: @session
      ]

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withData: (data) ->
    Promise.resolve(data).then (resolvedData) ->
      new Request @_key, @_table, resolvedData, @_session

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withMergedData: (data) ->
    Promise.resolve(data).then (resolvedData) ->
      new Request @_key, @_table, merge(@_data, resolvedData), @_session
