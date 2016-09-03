{log, isString, Validator} = require 'art-foundation'
{TimestampFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "fields are set correctly", ->
    simplePipeline = new SimplePipeline()
    .filter TimestampFilter

    assert.eq simplePipeline.fields.createdAt, Validator.fieldTypes.timestamp
    assert.eq simplePipeline.fields.updatedAt, Validator.fieldTypes.timestamp

  test "create", ->
    simplePipeline = new SimplePipeline()
    .filter TimestampFilter

    simplePipeline.create {}
    .then ({createdAt, updatedAt, id}) ->
      assert.isNumber createdAt
      assert.isNumber updatedAt
      assert.eq createdAt, updatedAt
      id

    .then (id) ->
      simplePipeline.update id, foo: "bar"

    .then ({createdAt, updatedAt}) ->
      assert.isNumber createdAt
      assert.isNumber updatedAt
      assert.gt updatedAt, createdAt
