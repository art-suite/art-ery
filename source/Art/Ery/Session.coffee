{EventedMixin} = require 'art-events'
{config} = require './Config'
{
  isPlainObject, Promise, BaseObject, merge, inspect, isString, isObject, log, plainObjectsDeepEq
  isBrowser
} = require 'art-standard-lib'
{Validator} = require 'art-validator'
{JsonStore} = require 'art-foundation'

module.exports = class Session extends EventedMixin require './ArtEryBaseObject'
  jsonStore = new JsonStore
  ###
  A global singleton Session is provided and used by default.
  Or multiple instances can be created and passed to the
  constructor of each Pipeline for per-pipeline custom sessions.
  ###
  @singletonClass()

  @property "data jsonStoreKey"

  constructor: (@_data = {}, @_jsonStoreKey = "Art.Ery.Session") ->

    if global?.document
      @_startPollingSession()

  _startPollingSession: ->
    setInterval(
      => @reloadSession()
      2000
    )

  reloadSession: ->
    @_sessionLoadPromise = null
    @loadSession()

  loadSession: ->
    @_sessionLoadPromise ||= if @jsonStoreKey
      jsonStore.getItem @jsonStoreKey
      .then (data) =>
        @data = data if isPlainObject data
    else
      Promise.resolve()

  @getter "sessionLoadPromise",
    loadedDataPromise: ->
      if config.location == "server"
        throw new Error "INTERNAL ERROR: Attempt to access the global session Serverside."
      @loadSession().then => @data

    sessionSignature: -> @_data?.signature

    inspectedObjects: -> @_data

  @setter
    data: (v) ->
      @queueEvent "change", data: v unless plainObjectsDeepEq v, @_data
      @_data = v
      @jsonStoreKey && jsonStore.setItem @jsonStoreKey, v

  reset: -> @data = {}

  @singleton.loadSession() if isBrowser