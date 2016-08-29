{log, isString} = require 'art-foundation'
{UuidFilter, TimestampFilter, ValidationFilter} = Neptune.Art.Ery.Filters
{ArtEryFluxModel} = Neptune.Art.Ery.Flux
Flux = require 'art-flux'
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  orderLog = []
  Chat = null
  chat = null
  setup ->
    Flux._reset()
    {chat} = class Chat extends ArtEryFluxModel
      @pipeline new SimplePipeline
      .filter     new UuidFilter
      .filter     new TimestampFilter
      .filter     new ValidationFilter
        user:     "trimmedString"
        message:  "trimmedString"

  test "chat instanceof FluxModel", ->
    assert.eq Flux.models.chat, chat
    assert.instanceOf Flux.models.chat, Flux.FluxModel

  test "myModel.create", ->
    chat.create user: "Shane", message: "Hi"

  test "create with missing required field", ->
    chat.create user: "Shane", message: ""
