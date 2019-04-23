{log, createWithPostCreate, RestClient, CommunicationStatus, objectKeyCount} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
{ApplicationState} = ArtFlux = Neptune.Art.Flux
{clientFailure, missing, serverFailure, clientFailureNotAuthorized} = CommunicationStatus

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

      test "returnFalse", ->
        pipelines.myRemote.returnFalse()
        .then (shouldBeFalse) ->
          assert.eq false, shouldBeFalse

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

      # this test doesn't even contain data...
      test "remoteResponse only contains status, session and props", ->
        pipelines.myRemote.handledByFilterRequest returnResponseObject: true
        .then (response) ->

          # there is always a session field
          assert.isString response.remoteResponse.status
          switch objectKeyCount response.remoteResponse
            when 1
              true #ok
            when 2
              # the only other field allowed is session
              assert.isPlainObject response.remoteResponse.session
            else
              assert.ok false, "only expecting 1 or 2 keys, got: #{Object.keys(response.remoteResponse).join ', '}"
          assert.eq response.handledBy.name, "POST http://localhost:8085/api/myRemote-handledByFilterRequest"

      test "privateRequestOkAsSubRequest", ->
        pipelines.myRemote.privateRequestOkAsSubRequest()

      test "myPrivateRequestType", ->
        assert.rejects pipelines.myRemote.myPrivateRequestType()
        .then (rejectsWith) ->
          assert.eq rejectsWith.info.response.status, clientFailureNotAuthorized

      test "non-existant request type", ->
        pipelines.myRemote.createRequest "nonExistantRequestType", {}
        .then (request)  -> pipelines.myRemote._processRequest request
        .then (response) -> assert.eq response.status, clientFailure

    "custom props": ->

      test "simulatePropsInput", ->
        pipelines.myRemote.simulatePropsInput props: name: "alice"
        .then (data) ->
          assert.eq data, name: "alice"

      test "simulatePropsOutput", ->
        pipelines.myRemote.simulatePropsOutput returnResponseObject: true
        .then ({props}) ->
          assert.eq props, myExtras: true

