{log, createWithPostCreate, RestClient} = require 'art-foundation'
{missing, Pipeline, pipelines} = Neptune.Art.Ery

module.exports = suite:
  pipelines: ->
    test "restPath", ->
      assert.eq pipelines.helloWorld.restPath, "/api/helloWorld"

    test "remoteServer", ->
      assert.eq pipelines.helloWorld.remoteServer, "http://localhost:8085"

  remote: ->
    test "heartbeat", ->
      RestClient.get "http://localhost:8085"
      .then (v) ->
        log v

    test "Hello George!", ->
      pipelines.helloWorld.get
        key: "George"
        returnResponseObject: true
      .then (v) ->
        assert.eq v.data, "Hello George!"
        assert.isPlainObject v.remoteRequest
        assert.isPlainObject v.remoteResponse

    test "Hello Alice!", ->
      pipelines.helloWorld.get key: "Alice"
      .then (data) -> assert.eq data, "Hello Alice!"
