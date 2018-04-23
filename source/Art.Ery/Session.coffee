{EventedMixin} = require 'art-events'
{config} = require './Config'
{
  isPlainObject, Promise, BaseObject, merge, inspect, isString, isObject, log, plainObjectsDeepEq
  isBrowser
  interval
  eq
  formattedInspect
} = require 'art-standard-lib'
{Validator} = require 'art-validation'
{JsonStore} = require 'art-foundation'
{jsonStore} = JsonStore
###
TODO:
  rename to SessionManager
  Art.Ery.session should be the raw session data
  Art.Ery.sessionManager should be this singleton
  NOTE: don't break the jsonStore name, though - keep it 'session'
  NOTE: this will break things which expect Art.Ery.session.data to be the session data

  rename: "data" should become "session"

  Pipeline.session
    should be split into: session (raw data) and sessionManager
    However, maybe we should ONLY have the 'session' getter,
    which returns raw-data.
    If you need custom sessions on a per-pipline basis, use
    inheritance... I like! it's simpler!

###

module.exports = class Session extends EventedMixin require './ArtEryBaseObject'
  ###
  A global singleton Session is provided and used by default.
  Or multiple instances can be created and passed to the
  constructor of each Pipeline for per-pipeline custom sessions.
  ###
  @singletonClass()

  constructor: (@_data = {}, @_jsonStoreKey) ->
    @_startPollingSession() if isBrowser

  _startPollingSession: ->
    interval 5000, => @reloadSession()

  reloadSession: ->
    @_sessionLoadPromise = null
    @loadSession()

  loadSession: ->
    @_sessionLoadPromise ?= (
      Promise.then => jsonStore.getItem @jsonStoreKey
      .then (data) =>
        unless eq data, @data
          # log "ArtErySession loaded from localStorage"
          @data = data
    )

  @getter "sessionLoadPromise data",
    jsonStoreKey: -> @_jsonStoreKey ? "Art.Ery.Session"

    loadedDataPromise: ->
      if config.location == "server"
        throw new Error "INTERNAL ERROR: Attempted to access the global session serverside. HINT: Use 'session: {}' for no-session requests."
      @loadSession().then => @data

    sessionSignature: -> @_data?.signature

    inspectedObjects: -> @_data

  @setter
    data: (data) ->
      if isPlainObject(data) && !plainObjectsDeepEq data, @_data
        @queueEvent "change", {data}
        # log "ArtErySession " + formattedInspect changed:
        #   old: merge @_data
        #   new: data
        jsonStore.setItem @jsonStoreKey, @_data = data

  reset: -> @data = {}

  @singleton.loadSession() if isBrowser