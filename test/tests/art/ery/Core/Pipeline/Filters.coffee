{log, createWithPostCreate, merge} = require 'art-foundation'
{missing, Pipeline} = Neptune.Art.Ery

module.exports = suite: ->

  test "filter logs", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers foo: (request) -> merge request.data, myHandlerRan: true

      @filter
        name: "MyBeforeFooFilter"
        before: foo: (request) -> log "beforeFilter", request.withMergedData myBeforeFooFilterRan: true

      @filter
        name: "MyAfterFooFilter"
        after: foo: (response) -> log "afterFilter", response.withMergedData myAfterFooFilterRan: true

    p = new MyPipeline
    p.foo
      returnResponseObject: true
    .then (response) ->
      assert.eq ["MyBeforeFooFilter"], (a.toString() for a in response.beforeFilterLog)
      assert.eq response.handledBy, handler: "foo"
      assert.eq ["MyAfterFooFilter"], (a.toString() for a in response.afterFilterLog)
      assert.eq response.data,
        myHandlerRan: true
        myBeforeFooFilterRan: true
        myAfterFooFilterRan: true
