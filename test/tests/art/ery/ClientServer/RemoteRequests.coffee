{log, createWithPostCreate, RestClient} = require 'art-foundation'
{missing, Pipeline, pipelines, session} = Neptune.Art.Ery

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
        assert.isString v
        assert.match v, /Art.Ery.pipeline/
      .catch (e) ->
        log.error "START THE TEST SERVER: npm run testServer"
        throw e

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

    test "missing", ->
      assert.rejects pipelines.helloWorld.missing()
      .then (response) ->
        log response
        assert.eq response.status, "missing"

    test "handledByFilterRequest", ->
      pipelines.helloWorld.handledByFilterRequest returnResponseObject: true
      .then (response) ->
        log response
        assert.eq response.remoteResponse.handledBy, "helloWorld: handledByFilterRequest: filter: handleByFilter"
        assert.eq response.handledBy, "POST http://localhost:8085/api/helloWorld-handledByFilterRequest"
