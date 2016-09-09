{log, formattedInspect, createWithPostCreate} = require 'art-foundation'
{Request, Filter} = Neptune.Art.Ery
SimplePipeline = require './SimplePipeline'

module.exports = suite:
  extendFields: ->
    test "on subclass", ->
      class MyFilter extends Filter
        @fields foo: "string"

      assert.eq MyFilter.getFields(), foo: "string"

    test "on subclass and sub-subclass", ->
      class MyFilter extends Filter
        @fields foo: "string"

      class MySubFilter extends MyFilter
        @fields bar: "number"

      assert.eq MyFilter.getFields(), foo: "string"
      assert.eq MySubFilter.getFields(), foo: "string", bar: "number"

    test "on subclass and subclass-instance", ->
      class MyFilter extends Filter
        @fields foo: "string"

      myFilter = new MyFilter
      myFilter.extendFields bar: "number"

      assert.eq MyFilter.getFields(), foo: "string"
      assert.eq myFilter.getFields(), foo: "string", bar: "number"

  order: ->
    orderLog = []

    class OrderTestFilter extends Filter
      constructor: (@str) -> super

      @before create: (request) ->
        orderLog.push "beforeCreate #{@str}"
        request.withData message: "#{request.data.message || ""}#{@str}"

      @after create: (response) ->
        orderLog.push "afterCreate #{@str}"
        response

    test "b > a > g > save > g > a > b", ->
      orderLog = []
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new OrderTestFilter "g"
        @filter new OrderTestFilter "a"
        @filter new OrderTestFilter "b"

      MyPipeline.singleton.create {}
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

  all: ->

    class OrderTestFilter extends Filter
      constructor: (@str) -> super

      @before all: (request) ->
        request.withData message: "#{if m = request.data.message then "#{m}\n" else ""}before_#{request.type}(#{@str})"

      @after all: (response) ->
        response.withData message: "#{if m = response.data.message then "#{m}\n" else ""}after_#{response.request.type}(#{@str})"

    test "before and after all", ->
      orderLog = []
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new OrderTestFilter "g"
        @filter new OrderTestFilter "a"
        @filter new OrderTestFilter "b"

      MyPipeline.singleton.create {}
      .then (savedData) ->
        assert.eq savedData.message, """
          before_create(b)
          before_create(a)
          before_create(g)
          after_create(g)
          after_create(a)
          after_create(b)
          """


