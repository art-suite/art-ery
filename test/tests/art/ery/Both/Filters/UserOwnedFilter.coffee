{log, createWithPostCreate, isString, Validator} = require 'art-foundation'
{session} = Neptune.Art.Ery
{UserOwnedFilter} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  userIdObject = userId: "abc123"

  test "doesn't set any fields", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter UserOwnedFilter

    assert.eq MyPipeline.getFields(), {}

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
