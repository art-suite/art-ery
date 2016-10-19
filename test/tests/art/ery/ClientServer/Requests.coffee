{log, createWithPostCreate, RestClient} = require 'art-foundation'
{missing, Pipeline, pipelines} = Neptune.Art.Ery

module.exports = suite: ->
  test "heartbeat", ->
    RestClient.get "http://localhost:8085"
    .then (v) ->
      log v

  test "HelloWorld", ->
    pipelines.helloWorld.get
      key: "George"
      returnResponseObject: true
    .then (v) ->
      log v
      assert.isPlainObject v.remoteRequest
      assert.isPlainObject v.remoteResponse