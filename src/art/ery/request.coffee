Foundation = require 'art-foundation'
{BaseObject, merge, inspect, isString, isObject, log} = Foundation

module.exports = class Request extends BaseObject
  constructor: (options) ->
    @validate options
    @_action  = options.action
    @_key     = options.key
    @_artery  = options.artery
    @_session = options.session
    @_data    = options.data

  @getter "action key artery session data"

  validate: ({action, key, artery, session, data}) ->
    throw "invalid action: #{action}" unless action?.match /^(get|update|create|delete)$/
    throw "invalid artery: #{inspect artery}" unless artery instanceof Neptune.Art.Ery.Artery
    throw "invalid session: #{inspect session}" unless isObject session

    if action == "create"
      throw "'create' action should not have a key: #{inspect key}" if key?
    else
      throw "invalid key: #{inspect key}" unless isString key

    if action == "get" || action == "delete"
      throw "'#{action}' action should not have data: #{inspect data}" if data?
    else
      throw "invalid data: #{inspect data}" unless isObject data

  @getter
    inspectObjects: ->
      [
        {inspect: => @class.namespacePath}
        @props
      ]
    props: ->
      action:   @action
      key:      @key
      artery:   @artery
      session:  @session
      data:     @data

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new Request merge @props, data: resolvedData

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withMergedData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new Request log merge @props, data: merge @data, resolvedData
