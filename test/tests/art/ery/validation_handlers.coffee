{log} = require 'art-foundation'
{missing} = require 'art-ery'
SimpleArtery = require './simple_artery'
{validateArtery} = require './simple_validator'

suite "Art.Ery.Validation Handlers", ->
  test "preprocess", ->
    simpleArtery = new SimpleArtery

    validateArtery simpleArtery,
      foo: preprocess: (o) -> o.toString()

    simpleArtery.create foo: 123
    .then (response) ->
      assert.eq response, []
