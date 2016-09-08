{log, createWithPostCreate, isString, Validator} = require 'art-foundation'
{TimestampFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "fields are set correctly", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter TimestampFilter

    assert.eq MyPipeline.singleton.fields.createdAt, Validator.fieldTypes.timestamp
    assert.eq MyPipeline.singleton.fields.updatedAt, Validator.fieldTypes.timestamp

  test "create", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter TimestampFilter

    MyPipeline.singleton.create {}
    .then ({createdAt, updatedAt, id}) ->
      assert.isNumber createdAt
      assert.isNumber updatedAt
      assert.eq createdAt, updatedAt
      id

    .then (id) ->
      MyPipeline.singleton.update id, foo: "bar"

    .then ({createdAt, updatedAt}) ->
      assert.isNumber createdAt
      assert.isNumber updatedAt
      assert.gt updatedAt, createdAt
