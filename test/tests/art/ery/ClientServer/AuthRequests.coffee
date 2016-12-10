{present, merge, isString, log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{missing, Pipeline, pipelines, session} = Neptune.Art.Ery
{clientFailure} = CommunicationStatus

module.exports = suite:
  authenticate:
    shouldFail: ->
      test "without username", ->
        assert.rejects pipelines.auth.authenticate()
        .then ({info:{response}}) ->
          assert.eq response.status, clientFailure
          assert.eq response.data, message: "username not present"

      test "without password", ->
        assert.rejects pipelines.auth.authenticate data: username: "alice"
        .then ({info:{response}}) -> assert.eq response.data, message: "password not present"

      test "with mismatching username and password", ->
        assert.rejects pipelines.auth.authenticate data: username: "alice", password: "hi"
        .then ({info:{response}}) -> assert.eq response.data, message: "username and password don't match"

    sessions: ->
      setup -> session.reset()
      test "works when password == username", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          assert.eq session.data.username, "alice"
          pipelines.auth.loggedInAs()
        .then ({username}) ->
          assert.eq session.data.username, "alice"
          assert.eq username, "alice"

      test "altering the session has no effect", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          assert.eq session.data.username, "alice"
          pipelines.auth.session.data = merge pipelines.auth.session.data, username: "bob"
          pipelines.auth.loggedInAs()
        .then ({username}) ->
          assert.eq session.data.username, "alice"
          assert.eq username, "alice"

      test "altering the session signature resets the session", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          assert.eq session.data.username, "alice"
          pipelines.auth.session.data = username: "bob"
          pipelines.auth.loggedInAs()
        .then ({username}) ->
          assert.eq session.data.username, "bob"
          assert.eq false, present username

