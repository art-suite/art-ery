Foundation = require 'art-foundation'
{EventedMixin} = require 'art-events'
{BaseObject, merge, inspect, isString, isObject, log, Validator, plainObjectsDeepEq, JsonStore} = Foundation

module.exports = class Session extends EventedMixin require './ArtEryBaseObject'
  jsonStore = new JsonStore
  jsonStoreKey = "Art.Ery.Session.data"
  ###
  A global singleton Session is provided and used by default.
  Or multiple instances can be created and passed to the
  constructor of each Pipeline for per-pipeline custom sessions.
  ###
  @singletonClass()

  @property "data"

  constructor: (@_data = {}) ->

  loadSession: ->
    @_sessionLoadPromise = jsonStore.getItem jsonStoreKey
    .then (data) =>
      log jsonStoreItem: key:jsonStoreKey, data: data
      @data = data if data

  @getter "sessionLoadPromise",
    sessionSignature: -> @_data?.signature

    inspectedObjects: -> @_data

  @setter
    data: (v) ->
      @queueEvent "change", data: v unless plainObjectsDeepEq v, @_data
      jsonStore.setItem jsonStoreKey, @_data = v

  reset: -> @data = {}
