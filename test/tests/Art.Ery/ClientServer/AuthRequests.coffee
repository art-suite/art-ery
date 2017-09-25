{objectWithout, present, merge, isString, log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{missing, Pipeline, pipelines, session} = Neptune.Art.Ery
{clientFailureNotAuthorized, clientFailure} = CommunicationStatus

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

      test "doesn't alter other session props", ->
        pipelines.auth.setFooSession data: foo: "bar"
        .then -> assert.eq session.data.foo, "bar"
        .then -> pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          assert.eq session.data.username, "alice"
          assert.eq session.data.foo, "bar"

      test "sessions get passed to sub-requests serverside", ->
        pipelines.auth.authenticate data: username: "Bill", password: "Bill"
        .then -> pipelines.myRemote.hello()
        .then (res) -> assert.eq res, "Hello, Bill!", "direct myRemote call"
        .then -> pipelines.auth.hello()
        .then (res) -> assert.eq res, "Hello, Bill!", "myRemote call via auth call"

      test "get with session", ->
        pipelines.auth.authenticate data: username: "Bill", password: "Bill"
        .then -> pipelines.auth.get()
        .then (username) ->
          assert.eq username, "Bill"

      test "altering the local session without changing the signature has no effect on the remote session", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          assert.eq session.data.username, "alice"
          pipelines.auth.session.data = merge pipelines.auth.session.data, username: "bob"
          pipelines.auth.loggedInAs()
        .then ({username}) ->
          assert.eq session.data.username, "bob"
          assert.eq username, "alice"

      test "clearing the session signature resets the remote session", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          assert.eq session.data.username, "alice"
          pipelines.auth.session.data = objectWithout pipelines.auth.session.data, "signature"
          pipelines.auth.loggedInAs()
        .then (response) ->
          assert.eq session.data.username?, false
          assert.doesNotExist response


      test "altering the session signature resets the remote session", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then ->
          assert.eq session.data.username, "alice"
          session.data.signature += "hack"
          pipelines.auth.loggedInAs()
        .then (response) ->
          assert.doesNotExist session.data.username
          assert.doesNotExist response

      test "unauthorized access", ->
        assert.rejects pipelines.auth.getRestrictedResource()
        .then (error) ->
          assert.eq error.info.response.status, clientFailureNotAuthorized

      test "authorized access", ->
        pipelines.auth.authenticate data: username: "alice", password: "alice"
        .then -> pipelines.auth.getRestrictedResource()
        .then ({secretSauce}) ->
          assert.isString secretSauce
