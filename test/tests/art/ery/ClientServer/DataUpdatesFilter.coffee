{log, createWithPostCreate, RestClient, CommunicationStatus} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
{ApplicationState} = ArtFlux = require 'art-flux'
{clientFailure, missing, serverFailure} = CommunicationStatus

module.exports = suite:
  "subrequests": ->
    preexistingKey = "abc123"
    setup ->
      pipelines.dataUpdatesFilterPipeline.reset
        data:
          "#{preexistingKey}": name: "initialAlice"

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
