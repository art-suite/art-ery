{log, isString, Validator} = require 'art-foundation'
{UuidFilter} = require 'art-ery'
SimplePipeline = require '../simple_pipeline'

suite "Art.Ery.Filters.UuidFilter", ->
  test "fields are set correctly", ->
    simplePipeline = new SimplePipeline()
    .filter UuidFilter

    assert.eq simplePipeline.fields.id, Validator.fieldTypes.id

  test "create", ->
    simplePipeline = new SimplePipeline()
    .filter UuidFilter

    simplePipeline.create {}
    .then ({id}) ->
      assert.isString id
