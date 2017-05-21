{log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
{ApplicationState} = ArtFlux = Neptune.Art.Flux
{clientFailure, missing, serverFailure} = CommunicationStatus

preexistingKey = "abc123"
testSetup = (initialRecords) ->
  pipelines.dataUpdatesFilterPipeline.reset
    data: initialRecords || "#{preexistingKey}": name: "initialAlice"
  .then ->
    assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, []

module.exports = suite:
  subrequests: ->
    setup -> testSetup()

    test "sub-create sets dataUpdates", ->
      pipelines.dataUpdatesFilterPipeline.subrequestTest
        returnResponseObject: true
        data:
          type: "create"
          data: name: "bill"

      .then ({props}) ->
        [id] = Object.keys props.dataUpdates.dataUpdatesFilterPipeline
        assert.eq
          dataUpdates:
            dataUpdatesFilterPipeline:
              "#{id}": name: "bill", createdAt: 123, updatedAt: 123, id: id

          data: name: "bill", createdAt: 123, updatedAt: 123, id: id

          props

    test "sub-update sets dataUpdates", ->
      pipelines.dataUpdatesFilterPipeline.subrequestTest
        returnResponseObject: true
        data:
          type: "update"
          key:  preexistingKey
          data: name: "bill"

      .then ({props}) ->
        id = preexistingKey
        assert.eq
          dataUpdates: dataUpdatesFilterPipeline: "#{id}": name:      "bill", updatedAt: 321
          data:        name:        "bill", updatedAt: 321

          props

    test "sub-delete sets dataDeletes", ->
      pipelines.dataUpdatesFilterPipeline.subrequestTest
        returnResponseObject: true
        data:
          type: "delete"
          key:  preexistingKey

      .then ({props}) ->
        id = preexistingKey
        assert.eq
          dataDeletes: dataUpdatesFilterPipeline: "#{id}": name:      "initialAlice"
          data:        name:        "initialAlice"

          props

    test "sub-get does not get logged", ->
      pipelines.dataUpdatesFilterPipeline.subrequestTest
        returnResponseObject: true
        data:
          type: "get"
          key:  preexistingKey

      .then ({props}) ->
        id = preexistingKey
        assert.eq
          data:        name:        "initialAlice"

          props

  "flux updates":
    "basic requests": ->
      setup -> testSetup()

      test "get", ->
        pipelines.dataUpdatesFilterPipeline.get
          key: preexistingKey

        .then ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataUpdated:
              model: "dataUpdatesFilterPipeline"
              key:   "abc123"
              data:  name: "initialAlice"
            ]

      test "update", ->
        pipelines.dataUpdatesFilterPipeline.update
          key: preexistingKey
          data: name: "bill"

        .then ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataUpdated:
              model: "dataUpdatesFilterPipeline"
              key:   "abc123"
              data:  name: "bill", updatedAt: 321
            ]

      test "delete", ->
        pipelines.dataUpdatesFilterPipeline.delete
          key: preexistingKey

        .then ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataDeleted:
              model: "dataUpdatesFilterPipeline"
              key:   "abc123"
              data:  name: "initialAlice"
            ]

      test "create", ->
        pipelines.dataUpdatesFilterPipeline.create
          data: name: "bill"

        .then ({id}) ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataUpdated:
              model: "dataUpdatesFilterPipeline"
              key:   id
              data:  name: "bill", createdAt: 123, updatedAt: 123, id: id

          ]

    subrequests: ->
      setup -> testSetup()

      test "get", ->
        pipelines.dataUpdatesFilterPipeline.subrequestTest
          data:
            type: "get"
            key: preexistingKey

        .then ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, []

      test "update", ->
        pipelines.dataUpdatesFilterPipeline.subrequestTest
          data:
            type: "update"
            key: preexistingKey
            data: name: "bill"

        .then ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataUpdated:
              model: "dataUpdatesFilterPipeline"
              key:   "abc123"
              data:  name: "bill", updatedAt: 321
            ]

      test "delete", ->
        pipelines.dataUpdatesFilterPipeline.subrequestTest
          data:
            type: "delete"
            key: preexistingKey

        .then ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataDeleted:
              model: "dataUpdatesFilterPipeline"
              key:   "abc123"
              data:  name: "initialAlice"
            ]

      test "create", ->
        pipelines.dataUpdatesFilterPipeline.subrequestTest
          data:
            type: "create"
            data: name: "bill"

        .then ({id}) ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataUpdated:
              model: "dataUpdatesFilterPipeline"
              key:   id
              data:  name: "bill", createdAt: 123, updatedAt: 123, id: id

          ]

    "query updates": ->

      test "create", ->
        testSetup()
        .then ->
          pipelines.dataUpdatesFilterPipeline.create
            data: name: "bill", email: "bill@imikimi.com"

        .then ({id}) ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataUpdated:
              model: "dataUpdatesFilterPipeline"
              key:   id
              data:
                name:      "bill"
                email:     "bill@imikimi.com"
                createdAt: 123
                updatedAt: 123
                id:        id

            {dataUpdated:
              model: "userByEmail"
              key:   "bill@imikimi.com"
              data:
                name:      "bill"
                email:     "bill@imikimi.com"
                createdAt: 123
                updatedAt: 123
                id:        id
            }
          ]

      test "get", ->
        testSetup "#{preexistingKey}": name: "alice", email: email = "alice@imikimi.com"
        .then ->

          pipelines.dataUpdatesFilterPipeline.get key: preexistingKey

        .then ({id}) ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataUpdated:
              model: "dataUpdatesFilterPipeline"
              key:   "abc123"
              data:  name: "alice", email: "alice@imikimi.com"

            {dataUpdated:
              model: "userByEmail"
              key:   "alice@imikimi.com"
              data:  name: "alice", email: "alice@imikimi.com"
            }
          ]

      test "delete", ->
        testSetup "#{preexistingKey}": name: "alice", email: email = "alice@imikimi.com"
        .then ->
          pipelines.dataUpdatesFilterPipeline.delete key: preexistingKey

        .then ({id}) ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataDeleted:
              model: "dataUpdatesFilterPipeline"
              key:   "abc123"
              data:  name: "alice", email: "alice@imikimi.com"

            {dataDeleted:
              model: "userByEmail"
              key:   "alice@imikimi.com"
              data:  name: "alice", email: "alice@imikimi.com"
            }
          ]

      test "update", ->
        testSetup "#{preexistingKey}": name: "alice", email: "alice@imikimi.com"
        .then ->
          pipelines.dataUpdatesFilterPipeline.update key: preexistingKey, data: email: "alicesNewEmail@imikimi.com"

        .then ({id}) ->
          assert.eq pipelines.dataUpdatesFilterPipeline.fluxLog, [
            dataUpdated:
              model: "dataUpdatesFilterPipeline"
              key:   "abc123"
              data:  name: "alice", email: "alicesNewEmail@imikimi.com", updatedAt: 321

            {dataUpdated:
              model: "userByEmail"
              key:   "alicesNewEmail@imikimi.com"
              data:  name: "alice", email: "alicesNewEmail@imikimi.com", updatedAt: 321
            }
          ]
