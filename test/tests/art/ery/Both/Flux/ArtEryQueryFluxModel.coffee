{log, isString, createWithPostCreate, merge} = require 'art-foundation'
{UuidFilter, TimestampFilter, ValidationFilter} = Neptune.Art.Ery.Filters
{ArtEryFluxModel, ArtEryQueryFluxModel} = Neptune.Art.Ery.Flux
SimplePipeline = require '../SimplePipeline'

{Pipeline} = Neptune.Art.Ery
{Flux} = Neptune.Art

module.exports = suite: ->
  setup ->
    Flux._reset()

    createWithPostCreate class Post extends Pipeline
      @query postByUserId: (request) ->
        [
          {userId: request.key, message: "Hi!"}
          {userId: request.key, message: "Really?"}
        ]

      @filter
        after: all: (response) ->
          response.withData (merge a, message: "#{a.message} :)" for a in response.data)

    ArtEryFluxModel.defineModelsForAllPipelines()

  test "query model defined", ->
    assert.instanceOf Flux.models.postByUserId, ArtEryQueryFluxModel

  test "query loadData goes through pipeline", ->
    Flux.models.postByUserId.loadData "abc123"
    .then (res) ->
      assert.eq res, [
        {userId: "abc123", message: "Hi! :)"}
        {userId: "abc123", message: "Really? :)"}
      ]

