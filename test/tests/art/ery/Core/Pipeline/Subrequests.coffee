{log, Promise, createWithPostCreate} = require 'art-foundation'
{pipelines, Pipeline, _reset} = Neptune.Art.Ery

module.exports = suite: ->
  setup ->
    _reset()
    createWithPostCreate class MyPipeline extends Pipeline

      @handlers
        get: ({key}) -> "Got #{key}?"

        myChanger: (request) -> "yay"

        triggerGachedGet: (request) ->
          {key} = request
          promises = [
            request.cachedGet "myPipeline", key
            request.cachedGet "myPipeline", key
            request.cachedGet "myPipeline", "chocolate #{key}"
          ]
          # two cachedGet requests with the same key return the same promise
          assert.eq promises[0], promises[1]

          # two cachedGet requests with the different keys return the different promises
          assert.neq promises[0], promises[2]
          Promise.all promises

  test "triggerCachedGet", ->
    pipelines.myPipeline.triggerGachedGet key: "milk", returnResponseObject: true
    .then ({data, subrequestCount}) ->
      assert.eq subrequestCount, 2
      assert.eq data, [
        "Got milk?"
        "Got milk?"
        "Got chocolate milk?"
      ]
