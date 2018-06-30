{timeout, log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
{ApplicationState} = ArtFlux = Neptune.Art.Flux
{clientFailure, missing, serverFailure} = CommunicationStatus

module.exports = suite: ->
  setup -> session.reset()
  test "setSessionA", ->
    pipelines.myRemote.setSessionA()
    .then ->
      assert.eq session.data.sessionA, true

  test "sequencial setSessionA and setSessionB don't clobber each other", ->
    pipelines.myRemote.setSessionA()
    .then -> pipelines.myRemote.setSessionB()
    .then ->
      assert.eq session.data.sessionA, true
      assert.eq session.data.sessionB, true

  test "requests which don't alter the session - don't alter the session nor return it", ->
    pipelines.myRemote.setSessionA()
    .then -> pipelines.myRemote.get returnResponseObject: true
    .then (response) ->
      assert.eq session.data.sessionA, true
      assert.doesNotExist response.remoteResponse.session
      assert.doesNotExist response.responseSession

  ###
  Two parallel requests will clober each other's sessions. It has to be this way
  because the both return different signed sessions. The client has no power
  to merge two signed sessions. It's cryptographically guaranteed.

  We could merge the unsigned data, BUT the signature won't match, and
  the server will only see one or the other session which was previously
  returned by the server.
  ###
  test "simultanious setSessionA and setSessionB DO clobber each other", ->
    Promise.all([
      pipelines.myRemote.setSessionA()
      pipelines.myRemote.setSessionB()
    ])
    .then ->
      assert.neq session.data.sessionA, session.data.sessionB

  test "most-recently-INITIATED request determines the session TEST-A", ->
    slowFinished = false
    p = pipelines.myRemote.slowSetSessionA()
    .then -> slowFinished = true

    timeout 10
    .then -> pipelines.myRemote.setSessionB()
    .then ->
      # second request is done, first isn't
      assert.eq slowFinished, false

    .then -> p # wait for p
    .then ->
      # now both requests are done...
      assert.eq slowFinished, true

      # second request determined the session
      assert.doesNotExist session.data.sessionA
      assert.eq session.data.sessionB, true

  test "preAlterSession", ->
    session.reset()
    assert.doesNotExist session.data.sessionWasPreAltered
    pipelines.myRemote.preAlterSession()
    .then ->
      assert.eq true, session.data.sessionWasPreAltered
