{log, isString, createWithPostCreate} = require 'art-foundation'
{UuidFilter, TimestampFilter, ValidationFilter} = Neptune.Art.Ery.Filters
{ArtEryFluxModel} = Neptune.Art.Ery.Flux
SimplePipeline = require '../SimplePipeline'

{Flux} = Neptune.Art

module.exports = suite: ->
  orderLog = []
  Chat = null
  chat = null
  setup ->

    Flux._reset()
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter     new UuidFilter
      @filter     new TimestampFilter
      @filter     new ValidationFilter
        user:     "trimmedString"
        message:  "trimmedString"

    {chat} = createWithPostCreate class Chat extends ArtEryFluxModel
      @pipeline MyPipeline.singleton

  test "chat instanceof FluxModel", ->
    assert.eq Flux.models.chat, chat
    assert.instanceOf Flux.models.chat, Flux.FluxModel

  test "myModel.create", ->
    chat.create user: "Shane", message: "Hi"

  test "create with missing required field", ->
    chat.create user: "Shane", message: ""
