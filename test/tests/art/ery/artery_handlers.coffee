{log, isString} = require 'art-foundation'
{missing} = require 'art-ery'
SimpleArtery = require './simple_artery'

addTimeStamps = (artery) ->
  artery.before "create", (request) ->
    now = (new Date).toString()
    request.withMergedData
      createdAt: now
      updatedAt: now

  artery.before "update", (request) ->
    now = (new Date).toString()
    request.withMergedData
      updatedAt: now

suite "Art.Ery.Artery Handlers", ->
  test "get -> missing", ->
    simpleArtery = new SimpleArtery
    addTimeStamps simpleArtery

    simpleArtery.create()
    .then (savedData) ->
      assert.ok isString savedData.createdAt
