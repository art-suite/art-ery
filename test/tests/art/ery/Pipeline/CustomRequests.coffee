{log, createWithPostCreate} = require 'art-foundation'
{missing, Pipeline} = Neptune.Art.Ery

module.exports = suite: ->
  test "myCustomRequest", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers
        myCustomRequest: (request) ->
          result: request.data.double + request.data.double

    pipeline = new MyPipeline
    pipeline.myCustomRequest data: double: "bar"
    .then (response) ->
      assert.eq response, result: "barbar"

  test "myCustomRequest with filter", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers
        myCustomRequest: (request) ->
          result: request.data.double + request.data.double
      @filter
        before: myCustomRequest: (request) ->
          request.withData double: request.data.double.toUpperCase()

    pipeline = new MyPipeline
    pipeline.myCustomRequest data: double: "bar"
    .then (response) ->
      assert.eq response, result: "BARBAR"
