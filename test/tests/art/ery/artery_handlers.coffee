{log, isString} = require 'art-foundation'
{missing, Handler} = require 'art-ery'
SimpleArtery = require './simple_artery'

class TimeStampHandler extends Handler
  beforeCreate: (request) ->
    now = (new Date).toString()
    request.withMergedData
      createdAt: now
      updatedAt: now

  beforeUpdate: (request) ->
    now = (new Date).toString()
    request.withMergedData
      updatedAt: now

suite "Art.Ery.Artery Handlers Basic", ->
  test "TimeStampHandler", ->
    simpleArtery = new SimpleArtery()
    .addHandler TimeStampHandler

    simpleArtery.create {}
    .then (savedData) ->
      assert.ok isString savedData.createdAt

suite "Art.Ery.Artery Handlers Order", ->
  orderLog = []

  class OrderTestHandler extends Handler
    constructor: (@str) ->

    beforeCreate: (request) ->
      orderLog.push "beforeCreate #{@str}"
      request.withData message: "#{request.data.message || ""}#{@str}"

    afterCreate: (response) ->
      orderLog.push "afterCreate #{@str}"
      response

  test "b > a > g > save > g > a > b", ->
    orderLog = []
    simpleArtery = new SimpleArtery()
    .addHandler new OrderTestHandler "g"
    .addHandler new OrderTestHandler "a"
    .addHandler new OrderTestHandler "b"

    simpleArtery.create {}
    .then (savedData) ->
      assert.eq orderLog, [
        "beforeCreate b"
        "beforeCreate a"
        "beforeCreate g"
        "afterCreate g"
        "afterCreate a"
        "afterCreate b"
      ]
      assert.eq savedData.message, "bag"
