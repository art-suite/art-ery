{log, isString, Validator} = require 'art-foundation'
{ValidationFilter} = require 'art-ery'
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "fields are set correctly", ->
    simplePipeline = new SimplePipeline()
    .filter new ValidationFilter
      foo: foo = preprocess: (o) -> "#{o}#{o}"
    .filter new ValidationFilter fields =
      bar: bar = validate: (v) -> (v | 0) == v
      id: id = Validator.fieldTypes.id

    assert.eq simplePipeline.fields,
      foo: foo
      bar: bar
      id: id

  test "preprocess", ->
    simplePipeline = new SimplePipeline()
    .filter new ValidationFilter
      foo: preprocess: (o) -> "#{o}#{o}"

    simplePipeline.create foo: 123
    .then (response) ->
      assert.eq response.foo, "123123"

  test "required field - missing", ->
    simplePipeline = new SimplePipeline()
    .filter new ValidationFilter
      foo: required: true

    simplePipeline.create bar: 123
    .then (data) ->
      throw "should not succeed"
    .catch (response) ->
      assert.eq response.error,
        invalidFields: []
        missingFields: ["foo"]

  test "required field - present", ->
    simplePipeline = new SimplePipeline()
    .filter new ValidationFilter
      foo: required: true

    simplePipeline.create foo: 123
    .then (data) ->
      assert.eq data.foo, 123

  test "validate - invalid", ->
    simplePipeline = new SimplePipeline()
    .filter new ValidationFilter
      foo: Validator.fieldTypes.trimmedString

    simplePipeline.create foo: 123
    .then (response) ->
      throw "should not succeed"
    .catch (response) ->
      assert.eq response.error,
        invalidFields: ["foo"]
        missingFields: []

  test "validate - valid with preprocessing", ->
    simplePipeline = new SimplePipeline()
    .filter new ValidationFilter
      foo: Validator.fieldTypes.trimmedString

    simplePipeline.create foo: "  123  "
    .then (data) ->
      assert.eq data.foo, "123"
