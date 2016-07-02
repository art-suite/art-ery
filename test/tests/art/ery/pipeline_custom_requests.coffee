{log} = require 'art-foundation'
{missing, Pipeline} = require 'art-ery'

suite "Art.Ery.Pipeline.Custom Requests", ->
  test "myCustomRequest", ->
    class MyPipeline extends Pipeline
      @handlers
        myCustomRequest: (request) ->
          result: request.data.double + request.data.double

    pipeline = new MyPipeline
    log pipeline.filters[0].before
    pipeline.myCustomRequest double: "bar"
    .then (response) ->
      assert.eq response, result: "barbar"

  test "myCustomRequest with filter", ->
    class MyPipeline extends Pipeline
      @handlers
        myCustomRequest: (request) ->
          result: request.data.double + request.data.double
      @filter
        before: myCustomRequest: (request) ->
          request.withData double: request.data.double.toUpperCase()

    pipeline = new MyPipeline
    log pipeline.filters
    pipeline.myCustomRequest double: "bar"
    .then (response) ->
      assert.eq response, result: "BARBAR"
