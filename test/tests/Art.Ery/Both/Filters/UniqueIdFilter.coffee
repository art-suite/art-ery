{log, createWithPostCreate, isString, Validator} = require 'art-foundation'
{UniqueIdFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "fields are set correctly", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter UniqueIdFilter

    assert.eq MyPipeline.getFields().id.dataType, "string"

  test "create", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter UniqueIdFilter

    (new MyPipeline).create {}
    .then ({id}) ->
      assert.match id, /^[-_a-zA-Z0-9\/\:]{12}$/
