{log, CommunicationStatus, isString, createWithPostCreate, BaseObject} = require 'art-foundation'
{UuidFilter, TimestampFilter, ValidationFilter} = Neptune.Art.Ery.Filters
{pipelines} = Neptune.Art.Ery
{ArtEryFluxModel} = Neptune.Art.Ery.Flux
SimplePipeline = require '../SimplePipeline'
{missing, success} = CommunicationStatus
{FluxSubscriptionsMixin} = Neptune.Art.Flux

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

  class MySubscriber extends FluxSubscriptionsMixin BaseObject
    ;

  test "subscribe when state is success", ->
    chat.pipeline.reset data: 123: name: "alice"
    .then ->
      mySubscriber = new MySubscriber
      new Promise (resolve) ->
        mySubscriber.subscribe
          modelName:  "chat"
          key:        "123"
          callback:   (fluxRecord) ->
            resolve() if fluxRecord.status == success

  test "subscribe when state is missing", ->
    chat.pipeline.reset data: 123: name: "alice"
    .then ->
      mySubscriber = new MySubscriber
      new Promise (resolve) ->
        mySubscriber.subscribe
          modelName:  "chat"
          key:        "456"
          callback:   (fluxRecord) ->
            resolve() if fluxRecord.status == missing

