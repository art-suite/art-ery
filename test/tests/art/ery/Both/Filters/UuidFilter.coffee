{log, createWithPostCreate, isString, Validator} = require 'art-foundation'
{UuidFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->

  test "fields are set correctly", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter UuidFilter

    assert.eq MyPipeline.getFields().id.dataType, "string"

  test "create", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter UuidFilter

    (new MyPipeline).create {}
    .then ({id}) ->
      assert.match id, /^[-a-f0-9]{36}$/
