{log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
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
