{log, createWithPostCreate, isString, Validator, merge} = require 'art-foundation'
{clientFailureNotAuthorized} = require 'art-communication-status'
{pipelines, session} = Neptune.Art.Ery
{UserOwnedFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

userIdObject = userId: "abc123"
wrongUserSession = userId: "wrongDude123"

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
          fields:
            foo: "string"
            bar: "string"
          userOwned: userCreatableFields: foo: true

      pipelines.myPipeline.create data: merge userIdObject, foo: "hi"
      .then ->
        assert.rejects pipelines.myPipeline.create data: merge userIdObject, bar: "hi"
        .then (rejectedWith) -> assert.eq rejectedWith.info.response.status, clientFailureNotAuthorized


    test "create with key is clientFailure", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userUpdatableFields: foo: true

      assert.clientFailure pipelines.myPipeline.create data: userIdObject, key: "foo"

    test "fail to create with different userId", ->
      session.data = wrongUserSession
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userUpdatableFields: foo: true

      assert.clientFailureNotAuthorized pipelines.myPipeline.create data: userIdObject

  userUpdatableFields: ->
    test "success to update foo", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userUpdatableFields: foo: true

      pipelines.myPipeline.create data: userIdObject
      .then ({id}) ->
        pipelines.myPipeline.update
          key: id
          data: foo: "hi"

    test "clientFailureNotAuthorized to update foo if wrong user", ->
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userUpdatableFields: foo: true

      pipelines.myPipeline.create data: userIdObject
      .then ({id}) ->
        session.data = wrongUserSession
        assert.clientFailureNotAuthorized pipelines.myPipeline.update
          key: id
          data: foo: "hi"

    test "clientFailureNotAuthorized to update bar", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @filter new UserOwnedFilter userUpdatableFields: foo: true

      pipelines.myPipeline.create data: userIdObject
      .then ({id}) ->
        assert.clientFailureNotAuthorized pipelines.myPipeline.update
          key: id
          data: bar: "hi"

    test "addDatabaseFilters", ->
      session.data = userIdObject
      createWithPostCreate class MyPipeline extends SimplePipeline
        @addDatabaseFilters
          fields:
            foo: "string"
            bar: "string"
          userOwned: userUpdatableFields: foo: true

      pipelines.myPipeline.create data: userIdObject
      .then ({id})->
        pipelines.myPipeline.update
          key: id
          data: foo: "hi"
        .then ->
          assert.clientFailureNotAuthorized pipelines.myPipeline.update
            key: id
            data: bar: "hi"
