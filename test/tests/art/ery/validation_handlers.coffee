{log} = require 'art-foundation'
{missing, Handler} = require 'art-ery'
SimpleArtery = require './simple_artery'
SimpleValidator = require './simple_validator'

class VerificationHandler extends Handler
  constructor: (fields) ->
    @_validator = new SimpleValidator fields

  beforeCreate: (request) -> request.withData @_validator.preCreate request.data
  beforeUpdate: (request) -> request.withData @_validator.preUpdate request.data

suite "Art.Ery.Validation Handlers", ->
  test "preprocess", ->
    simpleArtery = new SimpleArtery()
    .addHandler new VerificationHandler
      foo: preprocess: (o) -> "#{o}#{o}"

    simpleArtery.create foo: 123
    .then (response) ->
      assert.eq response.foo, "123123"

  test "required field - missing", ->
    simpleArtery = new SimpleArtery()
    .addHandler new VerificationHandler
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
    .addHandler new VerificationHandler
      foo: required: true

    simpleArtery.create foo: 123
    .then (data) ->
      assert.eq data.foo, 123

  test "validate - invalid", ->
    simpleArtery = new SimpleArtery()
    .addHandler new VerificationHandler
      foo: SimpleValidator.fieldTypes.trimmedString

    simpleArtery.create foo: 123
    .then (response) ->
      throw "should not succeed"
    .catch (response) ->
      assert.eq response.error,
        invalidFields: ["foo"]
        missingFields: []

  test "validate - valid with preprocessing", ->
    simpleArtery = new SimpleArtery()
    .addHandler new VerificationHandler
      foo: SimpleValidator.fieldTypes.trimmedString

    simpleArtery.create foo: "  123  "
    .then (data) ->
      assert.eq data.foo, "123"
