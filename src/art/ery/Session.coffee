Foundation = require 'art-foundation'
{EventedObject} = require 'art-events'
{BaseObject, merge, inspect, isString, isObject, log, Validator, plainObjectsDeepEq} = Foundation

module.exports = class Session extends require './ArtEryBaseObject'
  @include EventedObject
  ###
  A global singleton Session is provided and used by default.
  Or multiple instances can be created and passed to the
  constructor of each Pipeline for per-pipeline custom sessions.
  ###
  @singletonClass()

  @property "data"

  constructor: (@_data = {}) ->

  @getter
    inspectedObjects: -> @_data

  @setter
    data: (v) ->
      @queueEvent "change", data: v unless plainObjectsDeepEq v, @_data
      @_data = v

  reset: -> @data = {}
