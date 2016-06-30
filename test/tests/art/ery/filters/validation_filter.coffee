{log, Validator} = require 'art-foundation'
{missing, Filters} = require 'art-ery'
SimpleArtery = require '../simple_artery'

{ValidationFilter} = Filters

suite "Art.Ery.Pipeline.Filters.ValidationFilter", ->
  test "preprocess", ->
    simpleArtery = new SimpleArtery()
    .addFilter new ValidationFilter
      foo: preprocess: (o) -> "#{o}#{o}"

    simpleArtery.create foo: 123
    .then (response) ->
      assert.eq response.foo, "123123"

  test "required field - missing", ->
    simpleArtery = new SimpleArtery()
    .addFilter new ValidationFilter
      foo: required: true

    simpleArtery.create bar: 123
    .then (data) ->
      throw "should not succeed"
    .catch (response) ->
      assert.eq response.error,
        invalidFields: []
        missingFields: ["foo"]

  test "required field - present", ->
    simpleArtery = new SimpleArtery()
    .addFilter new ValidationFilter
      foo: required: true

    simpleArtery.create foo: 123
    .then (data) ->
      assert.eq data.foo, 123

  test "validate - invalid", ->
    simpleArtery = new SimpleArtery()
    .addFilter new ValidationFilter
      foo: Validator.fieldTypes.trimmedString

    simpleArtery.create foo: 123
    .then (response) ->
      throw "should not succeed"
    .catch (response) ->
      assert.eq response.error,
        invalidFields: ["foo"]
        missingFields: []

  test "validate - valid with preprocessing", ->
    simpleArtery = new SimpleArtery()
    .addFilter new ValidationFilter
      foo: Validator.fieldTypes.trimmedString

    simpleArtery.create foo: "  123  "
    .then (data) ->
      assert.eq data.foo, "123"
