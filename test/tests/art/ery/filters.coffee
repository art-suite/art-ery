{log, isString} = require 'art-foundation'
{missing, Filter, Filters} = require 'art-ery'
SimplePipeline = require './simple_pipeline'
{TimestampFilter} = Filters

suite "Art.Ery.Pipeline.Filters.Order", ->
  orderLog = []

  class OrderTestFilter extends Filter
    constructor: (@str) ->

    @before create: (request) ->
      orderLog.push "beforeCreate #{@str}"
      request.withData message: "#{request.data.message || ""}#{@str}"

    @after create: (response) ->
      orderLog.push "afterCreate #{@str}"
      response

  test "b > a > g > save > g > a > b", ->
    orderLog = []
    simplePipeline = new SimplePipeline()
    .filter new OrderTestFilter "g"
    .filter new OrderTestFilter "a"
    .filter new OrderTestFilter "b"

    simplePipeline.create {}
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
