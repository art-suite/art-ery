{EventedMixin} = require 'art-events'
{config} = require './Config'
{
  isPlainObject, Promise, BaseObject, merge, inspect, isString, isObject, log, plainObjectsDeepEq
  isBrowser
} = require 'art-standard-lib'
{Validator} = require 'art-validation'
{JsonStore} = require 'art-foundation'
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
        throw new Error "INTERNAL ERROR: Attempted to access the global session serverside. HINT: Use 'session: {}' for no-session requests."
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