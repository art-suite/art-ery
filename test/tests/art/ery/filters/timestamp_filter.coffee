{log, isString} = require 'art-foundation'
{missing, Filters} = require 'art-ery'
SimplePipeline = require '../simple_pipeline'
{TimestampFilter} = Filters

suite "Art.Ery.Filters.TimestampFilter", ->
  test "create", ->
    simplePipeline = new SimplePipeline()
    .filter TimestampFilter

    simplePipeline.create {}
    .then ({createdAt, updatedAt, key}) ->
      assert.isNumber createdAt
      assert.isNumber updatedAt
      assert.eq createdAt, updatedAt
      key

    .then (key) ->
      simplePipeline.update key, foo: "bar"

    .then ({createdAt, updatedAt}) ->
      assert.isNumber createdAt
      assert.isNumber updatedAt
      assert.gt updatedAt, createdAt
