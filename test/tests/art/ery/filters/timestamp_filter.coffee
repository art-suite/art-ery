{log, isString} = require 'art-foundation'
{missing, Filters} = require 'art-ery'
SimplePipeline = require '../simple_pipeline'
{TimestampFilter} = Filters

suite "Art.Ery.Pipeline.Filters.TimestampFilter", ->
  test "create", ->
    simplePipeline = new SimplePipeline()
    .addFilter TimestampFilter

    simplePipeline.create {}
    .then (savedData) ->
      assert.ok savedData.createdAt instanceof Date
      assert.ok savedData.updatedAt instanceof Date
