{log, isString, Validator} = require 'art-foundation'
{UuidFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
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
