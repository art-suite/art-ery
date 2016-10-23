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

  authenticate:
    shouldFail: ->
      test "without username", ->
        assert.rejects pipelines.auth.authenticate()
        .then (rejectedWith) -> assert.eq rejectedWith.data, message: "username not present"

      test "without password", ->
        assert.rejects pipelines.auth.authenticate data: username: "alice"
        .then (rejectedWith) -> assert.eq rejectedWith.data, message: "password not present"

      test "with mismatching username and password", ->
        assert.rejects pipelines.auth.authenticate data: username: "alice", password: "hi"
        .then (rejectedWith) -> assert.eq rejectedWith.data, message: "username and password don't match"

    sessions: ->
      test "works when password == username", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          assert.eq pipelines.auth.session.data.username, "alice"
          pipelines.auth.loggedInAs()
        .then (loggedInAs) -> assert.eq loggedInAs, "alice"

      test "setting the session to an exact clone is ok", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          pipelines.auth.session.data = username: "alice"
          pipelines.auth.loggedInAs()
        .then (loggedInAs) -> assert.eq loggedInAs, "alice"


      test "altering the session causes session reset", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          pipelines.auth.session.data = username: "bob"
          pipelines.auth.loggedInAs()
        .then (loggedInAs) -> assert.eq loggedInAs, "alice"

