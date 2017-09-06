{log, createWithPostCreate, isString, Validator, merge} = require 'art-foundation'
{clientFailureNotAuthorized} = require 'art-communication-status'
{pipelines, session} = Neptune.Art.Ery
{UserOwnedFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

userIdObject = userId: "abc123"
module.exports = suite:
  basic: ->

    test "doesn't set any fields", ->
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter UserOwnedFilter

      assert.eq MyPipeline.getFields(), {}

  create: ->
    test "create OK when userId == session.userId", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter UserOwnedFilter

      (new MyPipeline).create data: userIdObject

    test "create without userId sets it to session.userId", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter UserOwnedFilter

      (new MyPipeline).create data: {}
      .then ({userId}) ->
        assert.isString userId
        assert.eq userId, userIdObject.userId

    test "create FAIL when userId != session.userId", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter UserOwnedFilter

      assert.rejects (new MyPipeline).create data: userId: "WRONG ANSWER!"

  userCreatableFields: ->
    test "pass", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userCreatableFields: foo: true

      (new MyPipeline).create data: merge userIdObject, foo: "hi"

    test "no data", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userCreatableFields: foo: true

      (new MyPipeline).create()

    test "fail", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userCreatableFields: foo: true

      assert.rejects (new MyPipeline).create data: merge userIdObject, bar: "hi"
      .then (rejectedWith) -> assert.eq rejectedWith.info.response.status, clientFailureNotAuthorized

    test "addDatabaseFilters", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @addDatabaseFilters
          foo: "string"
          bar: "string"
          userOwned: userCreatableFields: foo: true

      pipelines.myPipeline.create data: merge userIdObject, foo: "hi"
      .then ->
        assert.rejects pipelines.myPipeline.create data: merge userIdObject, bar: "hi"
        .then (rejectedWith) -> assert.eq rejectedWith.info.response.status, clientFailureNotAuthorized

  userUpdatableFields: ->
    test "pass", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userUpdatableFields: foo: true

      pipelines.myPipeline.create data: userIdObject
      .then ({id}) ->
        pipelines.myPipeline.update
          key: id
          data: foo: "hi"

    test "fail", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userUpdatableFields: foo: true

      pipelines.myPipeline.create data: userIdObject
      .then ({id}) ->
        assert.rejects pipelines.myPipeline.create
          key: id
          data: bar: "hi"
        .then (rejectedWith) ->
          {status} = rejectedWith.info.response
          assert.eq status, clientFailureNotAuthorized

    test "addDatabaseFilters", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @addDatabaseFilters
          foo: "string"
          bar: "string"
          userOwned: userUpdatableFields: foo: true

      pipelines.myPipeline.create data: userIdObject
      .then ({id})->
        pipelines.myPipeline.update
          key: id
          data: foo: "hi"
        .then ->
          assert.rejects pipelines.myPipeline.update
            key: id
            data: bar: "hi"
          .then (rejectedWith) -> assert.eq rejectedWith.info.response.status, clientFailureNotAuthorized
