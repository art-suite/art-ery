Foundation = require 'art-foundation'
{EventedMixin} = require 'art-events'
{config} = require './Config'
{isPlainObject, BaseObject, merge, inspect, isString, isObject, log, Validator, plainObjectsDeepEq, JsonStore} = Foundation

module.exports = class Session extends EventedMixin require './ArtEryBaseObject'
  jsonStore = new JsonStore
  ###
  A global singleton Session is provided and used by default.
  Or multiple instances can be created and passed to the
  constructor of each Pipeline for per-pipeline custom sessions.
  ###
  @singletonClass {}, "Art.Ery.Session.singleton.data"

  @property "data jsonStoreKey"

  constructor: (@_data = {}, @_jsonStoreKey) ->

  loadSession: ->
    @_sessionLoadPromise ||= if @jsonStoreKey && config.location != "server"
      jsonStore.getItem @jsonStoreKey
      .then (data) =>
        log loadSession: {@jsonStoreKey, @data}
        @data = data if isPlainObject data
    else
      Promise.resolve()

  @getter "sessionLoadPromise",
    loadedDataPromise: -> @loadSession().then => @data
    sessionSignature: -> @_data?.signature

    inspectedObjects: -> @_data

  @setter
    data: (v) ->
      @queueEvent "change", data: v unless plainObjectsDeepEq v, @_data
      @jsonStoreKey && jsonStore.setItem @jsonStoreKey, @_data = v

  reset: -> @_data = {}
