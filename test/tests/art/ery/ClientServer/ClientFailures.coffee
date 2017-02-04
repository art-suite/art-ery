{log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
{ApplicationState} = ArtFlux = require 'art-flux'
{clientFailure, missing, serverFailure} = CommunicationStatus

module.exports = suite: ->

  test "beforeFilterClientFailure", ->
    assert.rejects pipelines.clientFailures.beforeFilterClientFailure()
    .then (rejectsWith) ->
      {response} = rejectsWith.info
      assert.match rejectsWith.message, "beforeFilterClientFailure allways fails"
      assert.eq response.status, clientFailure

  test "afterFilterClientFailure", ->
    assert.rejects pipelines.clientFailures.afterFilterClientFailure()
    .then (rejectsWith) ->
      {response} = rejectsWith.info
      assert.match rejectsWith.message, "afterFilterClientFailure allways fails"
      assert.eq response.status, clientFailure

  test "handlerClientFailure", ->
    assert.rejects pipelines.clientFailures.handlerClientFailure()
    .then (rejectsWith) ->
      {response} = rejectsWith.info
      assert.match rejectsWith.message, "handlerClientFailure allways fails"
      assert.eq response.status, clientFailure
