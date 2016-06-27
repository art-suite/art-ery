{log, isString} = require 'art-foundation'
{missing, Handlers} = require 'art-ery'
SimpleArtery = require '../simple_artery'
{TimeStampHandler} = Handlers

suite "Art.Ery.Artery.Handlers.TimeStampHandler", ->
  test "create", ->
    simpleArtery = new SimpleArtery()
    .addHandler TimeStampHandler

    simpleArtery.create {}
    .then (savedData) ->
      assert.ok savedData.createdAt instanceof Date
      assert.ok savedData.updatedAt instanceof Date
