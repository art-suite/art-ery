{log, isString} = require 'art-foundation'
{missing, Filter, Filters} = require 'art-ery'
SimpleArtery = require './simple_artery'
{TimestampFilter} = Filters

suite "Art.Ery.Pipeline.Filters.Order", ->
  orderLog = []

  class OrderTestHandler extends Filter
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
    .addFilter new OrderTestHandler "g"
    .addFilter new OrderTestHandler "a"
    .addFilter new OrderTestHandler "b"

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
