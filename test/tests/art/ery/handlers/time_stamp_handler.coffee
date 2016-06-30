{log, isString} = require 'art-foundation'
{missing, Filters} = require 'art-ery'
SimpleArtery = require '../simple_artery'
{TimestampFilter} = Filters

suite "Art.Ery.Pipeline.Filters.TimestampFilter", ->
  test "create", ->
    simpleArtery = new SimpleArtery()
    .addFilter TimestampFilter

    simpleArtery.create {}
    .then (savedData) ->
      assert.ok savedData.createdAt instanceof Date
      assert.ok savedData.updatedAt instanceof Date
