{log, createWithPostCreate, RestClient,
 CommunicationStatus} = require 'art-foundation'
{Pipeline, pipelines, session} = Neptune.Art.Ery
{ApplicationState} = ArtFlux = require 'art-flux'
{clientFailure, missing, serverFailure} = CommunicationStatus

module.exports = suite: ->
  test "get", ->
    pipelines.compoundKeys.reset data: "postAbc/user123": recordData = followerCount: 2
    .then ->
      pipelines.compoundKeys.get key: postId: "postAbc", userId: "user123"

    .then (data) ->
      assert.eq data, recordData

  test "create", ->
    pipelines.compoundKeys.create data: recordData = postId: "postAbc_2", userId: "user123_2", followerCount: 23
    .then (createdData) ->
      assert.eq createdData, recordData
      pipelines.compoundKeys.get key: recordData

    .then (data) ->
      assert.eq data, recordData

  test "update", ->
    recordData = null
    pipelines.compoundKeys.reset data: "postAbc_3/user123_3": followerCount: 2
    .then ->
      pipelines.compoundKeys.update
        key: postId: "postAbc_3", userId: "user123_3"
        data: recordData = followerCount: 3

    .then ->
      pipelines.compoundKeys.get key: postId: "postAbc_3", userId: "user123_3"

    .then (data) ->
      assert.eq data, recordData
