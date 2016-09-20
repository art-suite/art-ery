Foundation = require 'art-foundation'
{BaseObject, merge, inspect, isString, isObject, log, Validator, CommunicationStatus, arrayWith, w} = Foundation
ArtEry = require './namespace'
{success, missing, failure, validStatus} = CommunicationStatus

validator = new Validator
  type:     w "required string"
  pipeline: required: instanceof: Neptune.Art.Ery.Pipeline
  session:  w "required object"
  data:     "object"
  key:      "string"

module.exports = class Request extends require './RequestResponseBase'
  constructor: (options) ->
    super
    validator.preCreateSync options, context: "Request options"
    {@type, @key, @pipeline, @session, @data, @serverSideOrigin} = options

  @property "type key pipeline session data serverSideOrigin"

  toString: -> "ArtEry.Request(#{@type} key: #{@key}, hasData: #{!!@data})"

  requireServerSideOrigin: ->
    unless @serverSideOrigin
      throw @failure data: message: "serverSideOrigin required"
    @

  @getter
    request: -> @

    props: ->
      pipeline:         @pipeline
      type:             @type
      key:              @key
      session:          @session
      data:             @data
      filterLog:        @filterLog
