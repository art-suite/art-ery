{log, isString, createWithPostCreate, Validator} = require 'art-foundation'
{ValidationFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "fields are set correctly", ->
    foo = bar = id = null
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter
        foo: foo = preprocess: (o) -> "#{o}#{o}"
      @filter new ValidationFilter fields =
        bar: bar = validate: (v) -> (v | 0) == v
        id: id = Validator.fieldTypes.id

    assert.eq MyPipeline.singleton.fields,
      foo: foo
      bar: bar
      id: id

  test "preprocess", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter
        foo: preprocess: (o) -> "#{o}#{o}"

    MyPipeline.singleton.create foo: 123
    .then (response) ->
      assert.eq response.foo, "123123"

  test "required field - missing", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter
        foo: required: true

    MyPipeline.singleton.create bar: 123
    .then (data) ->
      throw "should not succeed"
    .catch (response) ->
      assert.eq response.error,
        validationFailure: "preCreate: ValidationFilter for myPipeline fields missing"
        missingFields:     foo: undefined

  test "required field - present", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter
        foo: required: true

    MyPipeline.singleton.create foo: 123
    .then (data) ->
      assert.eq data.foo, 123

  test "validate - invalid", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter
        foo: Validator.fieldTypes.trimmedString

    MyPipeline.singleton.create foo: 123
    .then (response) ->
      throw "should not succeed"
    .catch (response) ->
      assert.eq response.error,
        validationFailure: "preCreate: ValidationFilter for myPipeline fields invalid"
        invalidFields:     foo: 123

  test "validate - valid with preprocessing", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new ValidationFilter
        foo: Validator.fieldTypes.trimmedString

    MyPipeline.singleton.create foo: "  123  "
    .then (data) ->
      assert.eq data.foo, "123"
