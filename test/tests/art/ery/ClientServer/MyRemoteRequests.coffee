{log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
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
      test "heartbeat", ->
        RestClient.get "http://localhost:8085"
        .then (v) ->
          assert.isString v
          assert.match v, /Art.Ery.pipeline/
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

    "custom props": ->

      test "simulatePropsInput", ->
        pipelines.myRemote.simulatePropsInput props: name: "alice"
        .then (data) ->
          assert.eq data, name: "alice"

      test "simulatePropsOutput", ->
        pipelines.myRemote.simulatePropsOutput returnResponseObject: true
        .then ({props}) ->
          assert.eq props, myExtras: true

    dataUpdates: ->
      test "update request", ->
        pipelines.myRemote.update returnResponseObject: true, key: "foo", data: name: "alice"
        .then ({props}) ->
          assert.eq
            data:
              name: "alice"
              updatedAt: props.data.updatedAt - 0
            props

      test "create request", ->
        pipelines.myRemote.create returnResponseObject: true, key: "foo", data: name: "alice"
        .then ({props}) ->
          assert.eq
            data:
              name: "alice"
              createdAt: props.data.updatedAt - 0
              updatedAt: props.data.updatedAt - 0
            props

      test "subupdates", ->
        pipelines.myRemote.subupdates
          returnResponseObject: true
          data:
            d1: name: "alice"
            d2: name: "bill"
        .then ({props}) ->
          assert.eq
            data: {}
            props
