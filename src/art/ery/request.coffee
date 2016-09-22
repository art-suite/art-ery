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
    {@type, @key, @pipeline, @session, @data, @originatedOnServer} = options

  @property "type key pipeline session data originatedOnServer"

  toString: -> "ArtEry.Request(#{@type} key: #{@key}, hasData: #{!!@data})"

  requireServerOrigin: (message = "(no further explanation)")->
    unless @originatedOnServer
      throw @failure data: message: "Request must originated on server: #{message}"
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
