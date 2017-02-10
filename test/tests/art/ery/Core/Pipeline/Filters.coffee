{log, createWithPostCreate, merge} = require 'art-foundation'
{missing, Pipeline, pipelines} = Neptune.Art.Ery

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

  test "before filters by location", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers foo: (request) -> merge request.data, myHandlerRan: true

      @filter
        location: "client"
        name: "beforeFooClient"
        before: foo: (request) -> request

      @filter
        location: "both"
        name: "beforeFooBoth"
        before: foo: (request) -> request

      @filter
        location: "server"
        name: "beforeFooServer"
        before: foo: (request) -> request

    assert.eq ["both", "client"], (f.location for f in pipelines.myPipeline.getBeforeFilters requestType: "foo", location: "client")
    assert.eq ["server", "both"], (f.location for f in pipelines.myPipeline.getBeforeFilters requestType: "foo", location: "server")
    assert.eq ["server", "both", "client"], (f.location for f in pipelines.myPipeline.getBeforeFilters requestType: "foo", location: "both")

  test "after filters by location", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers foo: (request) -> merge request.data, myHandlerRan: true

      @filter
        location: "client"
        name: "afterFooClient"
        after: foo: (request) -> request

      @filter
        location: "both"
        name: "afterFooBoth"
        after: foo: (request) -> request

      @filter
        location: "server"
        name: "afterFooServer"
        after: foo: (request) -> request

    assert.eq ["client", "both"], (f.location for f in pipelines.myPipeline.getAfterFilters requestType: "foo", location: "client")
    assert.eq ["both", "server"], (f.location for f in pipelines.myPipeline.getAfterFilters requestType: "foo", location: "server")
    assert.eq ["client", "both", "server"], (f.location for f in pipelines.myPipeline.getAfterFilters requestType: "foo", location: "both")
