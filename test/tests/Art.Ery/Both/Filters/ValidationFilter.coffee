{log, isString, createWithPostCreate} = require 'art-foundation'
{ValidationFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

{FieldTypes} = require 'art-validation'

module.exports = suite: ->
  test "fields are set correctly", ->
    foo = bar = id = null
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter fields:
        foo: foo = preprocess: (o) -> "#{o}#{o}"
      @filter new ValidationFilter fields: fields =
        bar: bar = validate: (v) -> (v | 0) == v
        id: id = FieldTypes.id

    assert.eq MyPipeline.singleton.fields,
      foo: foo
      bar: bar
      id: id

  test "preprocess", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter fields:
        foo: preprocess: (o) -> "#{o}#{o}"

    MyPipeline.singleton.create data: foo: 123
    .then (response) ->
      assert.eq response.foo, "123123"

  test "required field - missing", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter fields:
        foo: required: true

    assert.rejects MyPipeline.singleton.create data: bar: 123
    .then ({info: {response}}) ->
      assert.eq response.data.errors, foo: "missing"

  test "required field - present", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter fields:
        foo: required: true

    MyPipeline.singleton.create data: foo: 123
    .then (data) ->
      assert.eq data.foo, 123

  test "validate - invalid", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter fields:
        foo: FieldTypes.trimmedString

    assert.rejects MyPipeline.singleton.create data: foo: 123
    .then ({info: {response}}) -> assert.eq response.data.errors, foo: "invalid"

  test "validate - valid with preprocessing", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter fields:
        foo: FieldTypes.trimmedString

    MyPipeline.singleton.create data: foo: "  123  "
    .then (data) ->
      assert.eq data.foo, "123"
