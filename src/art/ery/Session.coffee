Foundation = require 'art-foundation'
{BaseObject, merge, inspect, isString, isObject, log, Validator} = Foundation

module.exports = class Session extends require './ArtEryBaseObject'
  ###
  A global singleton Session is provided and used by default.
  Or multiple instances can be created and passed to the
  constructor of each Pipeline for per-pipeline custom sessions.
  ###
  @singletonClass()

  @property "data"
  constructor: (@_data = {}) ->

