{log, isString, Validator} = require 'art-foundation'
{TimestampFilter} = require 'art-ery'
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
