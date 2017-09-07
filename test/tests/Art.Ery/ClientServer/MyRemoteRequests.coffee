{log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
{ApplicationState} = ArtFlux = Neptune.Art.Flux
{clientFailure, missing, serverFailure} = CommunicationStatus

module.exports = suite:
  responseStatuses: ->
    test "simulateMissing", ->
      assert.rejects pipelines.myRemote.simulateMissing()
      .then ({info:{response}}) -> assert.eq response.status, missing

    test "simulateClientFailure", ->
      assert.rejects pipelines.myRemote.simulateClientFailure()
      .then ({info:{response}}) -> assert.eq response.status, clientFailure

    test "simulateServerFailure", ->
      assert.rejects pipelines.myRemote.simulateServerFailure()
      .then ({info:{response}}) -> assert.eq response.status, serverFailure

  pipelines: ->
    test "restPath", ->
      assert.eq pipelines.myRemote.restPath, "/api/myRemote"

    test "remoteServer", ->
      assert.eq pipelines.myRemote.remoteServer, "http://localhost:8085"

  remote:
    basic: ->
      test "/api", ->
        RestClient.get "http://localhost:8085/api"
        .then (v) ->
          assert.isString v
          assert.match v, /Art.Ery.*api/i
        .catch (e) ->
          log.error "START THE TEST SERVER: npm run testServer"
          throw e

      test "static index.html", ->
        RestClient.get "http://localhost:8085"
        .then (v) ->
          assert.isString v
          assert.match v, "a href"
        .catch (e) ->
          log.error "START THE TEST SERVER: npm run testServer"
          throw e

      test "Hello George!", ->
        pipelines.myRemote.get
          key: "George"
          returnResponseObject: true
        .then (v) ->
          assert.eq v.data, "Hello George!"
          assert.isPlainObject v.remoteRequest
          assert.isPlainObject v.remoteResponse

      test "Buenos dias George!", ->
        pipelines.myRemote.get
          key: "George"
          data: greeting: "Buenos dias"
          returnResponseObject: true
        .then (v) ->
          assert.eq v.data, "Buenos dias George!"
          assert.isPlainObject v.remoteRequest
          assert.isPlainObject v.remoteResponse

      test "Hello Alice!", ->
        pipelines.myRemote.get key: "Alice"
        .then (data) -> assert.eq data, "Hello Alice!"

      test "handledByFilterRequest", ->
        pipelines.myRemote.handledByFilterRequest returnResponseObject: true
        .then (response) ->
          assert.eq response.remoteResponse.handledBy, beforeFilter: "handleByFilter"
          assert.eq response.handledBy, "POST http://localhost:8085/api/myRemote-handledByFilterRequest"

      test "privateRequestOkAsSubRequest", ->
        pipelines.myRemote.privateRequestOkAsSubRequest()

      test "myPrivateRequestType", ->
        assert.rejects pipelines.myRemote.myPrivateRequestType()
        .then (rejectsWith) ->
          assert.eq rejectsWith.info.response.status, missing

      test "non-existant request type", ->
        request = pipelines.myRemote.createRequest "nonExistantRequestType", {}
        pipelines.myRemote._processRequest request
        .then (response) -> assert.eq response.status, missing

    "custom props": ->

      test "simulatePropsInput", ->
        pipelines.myRemote.simulatePropsInput props: name: "alice"
        .then (data) ->
          assert.eq data, name: "alice"

      test "simulatePropsOutput", ->
        pipelines.myRemote.simulatePropsOutput returnResponseObject: true
        .then ({props}) ->
          assert.eq props, myExtras: true

