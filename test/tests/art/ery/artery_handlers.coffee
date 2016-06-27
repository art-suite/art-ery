{log, isString} = require 'art-foundation'
{missing, Handler, Handlers} = require 'art-ery'
SimpleArtery = require './simple_artery'
{TimeStampHandler} = Handlers

suite "Art.Ery.Artery.Handlers.Order", ->
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
