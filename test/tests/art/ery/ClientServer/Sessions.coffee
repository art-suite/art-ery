{log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
{ApplicationState} = ArtFlux = require 'art-flux'
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

  test "simultanious setSessionA and setSessionB don't clobber each other", ->
    Promise.all([
      pipelines.myRemote.setSessionA()
      pipelines.myRemote.setSessionB()
    ])
    .then ->
      assert.eq session.data.sessionA, true
      assert.eq session.data.sessionB, true
