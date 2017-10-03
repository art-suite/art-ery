{log, createWithPostCreate} = require 'art-foundation'
{missing, Pipeline} = Neptune.Art.Ery

module.exports = suite:
  afterFilterFailures: ->
    test "internal error", ->
      filterLog = []
      createWithPostCreate class MyPipeline extends Pipeline
        @handlers create: (request) -> foo: 1, bar: 2
        @filter name: "myFilter1", after: create: (response) -> filterLog.push "myFilter1"; response
        @filter name: "myFilter2", after: create: (response) -> filterLog.push "myFilter2"; throw new Error "internal oops"
        @filter name: "myFilter3", after: create: (response) -> filterLog.push "myFilter3"; response

      p = new MyPipeline
      assert.rejects p.create()
      .then (error) ->
        assert.eq filterLog, ["myFilter1", "myFilter2"]
        assert.eq error.message, "internal oops"

    test "clientFailure", ->
      createWithPostCreate class MyPipeline extends Pipeline
        @handlers create: (request) -> foo: 1, bar: 2
        @filter name: "myFilter1", after: create: (response) -> response
        @filter name: "myFilter2", after: create: (response) -> response.clientFailure "you lose!"
        @filter name: "myFilter3", after: create: (response) -> response

      p = new MyPipeline
      assert.rejects p.create()
      .then (error) ->
        {response} = error.info
        assert.eq response.beforeFilterLog, []
        assert.eq response.afterFilterLog, ["myFilter1", "myFilter2"]
        assert.eq response.handledBy, handler: "create"
        assert.eq response.data.message, "you lose!"

  beforeFilterFailures: ->
    test "clientFailure", ->
      createWithPostCreate class MyPipeline extends Pipeline
        @handlers create: (request) -> foo: 1, bar: 2
        @filter name: "myFilter1", before: create: (response) -> response
        @filter name: "myFilter2", before: create: (response) -> response.clientFailure "you lose!"
        @filter name: "myFilter3", before: create: (response) -> response

      p = new MyPipeline
      assert.rejects p.create()
      .then (error) ->
        {response} = error.info
        assert.eq response.beforeFilterLog, ["myFilter3", "myFilter2"]
        assert.eq response.afterFilterLog, []
        assert.eq response.handledBy, undefined
        assert.eq response.data.message, "you lose!"

    test "internal error", ->
      filterLog = []
      createWithPostCreate class MyPipeline extends Pipeline
        @handlers create: (request) -> foo: 1, bar: 2
        @filter before: create: (response) -> filterLog.push "myFilter1"; response
        @filter before: create: (response) -> filterLog.push "myFilter2"; throw new Error "internal oops"
        @filter before: create: (response) -> filterLog.push "myFilter3"; response

      p = new MyPipeline
      assert.rejects p.create()
      .then (error) ->
        assert.eq filterLog, ["myFilter3", "myFilter2"]
        assert.eq error.message, "internal oops"
