{log, createWithPostCreate, isString, Validator} = require 'art-foundation'
{Pipeline} = Neptune.Art.Ery
{AfterEventsFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "does not define fields", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @filter AfterEventsFilter

    assert.eq MyPipeline.getFields(), {}

  test "AfterEventsFilter.on", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends Pipeline
      @filter AfterEventsFilter
      @handler
        myRequest: -> "hello"

    new Promise (resolve) ->
      AfterEventsFilter.on "myPipeline", "myRequest", (response) ->
        assert.eq response.data, "hello"
        resolve()

      myPipeline.myRequest {}

  test "AfterEventsFilter.registerPipelineListener", ->
    new Promise (resolve) ->
      {myPipeline} = createWithPostCreate class MyPipeline extends Pipeline
        @filter AfterEventsFilter
        @handler
          myRequest: -> "hello"

        handleRequestAfterEvent: (response) ->
          assert.eq response.data, "hello"
          resolve()

      AfterEventsFilter.registerPipelineListener myPipeline, "myRequest"

      myPipeline.myRequest {}
