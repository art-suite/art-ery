Foundation = require 'art-foundation'
{EventedObject} = require 'art-events'
{BaseObject, merge, inspect, isString, isObject, log, Validator, plainObjectsDeepEq, JsonStore} = Foundation

module.exports = class Session extends require './ArtEryBaseObject'
  jsonStore = new JsonStore
  jsonStoreKey = "Art.Ery.Session.data"
  @include EventedObject
  ###
  A global singleton Session is provided and used by default.
  Or multiple instances can be created and passed to the
  constructor of each Pipeline for per-pipeline custom sessions.
  ###
  @singletonClass()

  @property "data"

  constructor: (@_data = {}) ->
    super

  loadSession: ->
    @_sessionLoadPromise = jsonStore.getItem jsonStoreKey
    .then (data) =>
      log jsonStoreItem: key:jsonStoreKey, data: data
      @data = data if data

  @getter "sessionLoadPromise",
    inspectedObjects: -> @_data

  @setter
    data: (v) ->
      @queueEvent "change", data: v unless plainObjectsDeepEq v, @_data
      jsonStore.setItem jsonStoreKey, @_data = v

  reset: -> @data = {}
