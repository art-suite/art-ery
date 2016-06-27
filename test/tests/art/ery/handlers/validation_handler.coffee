{log, Validator} = require 'art-foundation'
{missing, Handlers} = require 'art-ery'
SimpleArtery = require '../simple_artery'

{ValidationHandler} = Handlers

suite "Art.Ery.Artery.Handlers.ValidationHandler", ->
  test "preprocess", ->
    simpleArtery = new SimpleArtery()
    .addHandler new ValidationHandler
      foo: preprocess: (o) -> "#{o}#{o}"

    simpleArtery.create foo: 123
    .then (response) ->
      assert.eq response.foo, "123123"

  test "required field - missing", ->
    simpleArtery = new SimpleArtery()
    .addHandler new ValidationHandler
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
    .addHandler new ValidationHandler
      foo: required: true

    simpleArtery.create foo: 123
    .then (data) ->
      assert.eq data.foo, 123

  test "validate - invalid", ->
    simpleArtery = new SimpleArtery()
    .addHandler new ValidationHandler
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
    .addHandler new ValidationHandler
      foo: Validator.fieldTypes.trimmedString

    simpleArtery.create foo: "  123  "
    .then (data) ->
      assert.eq data.foo, "123"
