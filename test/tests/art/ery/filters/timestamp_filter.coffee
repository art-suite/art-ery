{log, isString} = require 'art-foundation'
{missing, Filters} = require 'art-ery'
SimplePipeline = require '../simple_pipeline'
{TimestampFilter} = Filters

suite "Art.Ery.Filters.TimestampFilter", ->
  test "create", ->
    simplePipeline = new SimplePipeline()
    .filter TimestampFilter

    simplePipeline.create {}
    .then (savedData) ->
      log savedData
      assert.ok savedData.createdAt instanceof Date
      assert.ok savedData.updatedAt instanceof Date
