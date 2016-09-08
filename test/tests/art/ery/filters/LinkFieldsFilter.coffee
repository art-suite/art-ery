{log, createWithPostCreate, isString, Validator} = require 'art-foundation'
{Pipeline, Filters, pipelines} = Neptune.Art.Ery
{LinkFieldsFilter} = Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  setup ->
    Neptune.Art.Ery.PipelineRegistry._reset()

  test "fields are set correctly", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new LinkFieldsFilter fields =
        user: required: link: "user"
        post: link: "post"

    assert.eq MyPipeline.getFields(),
      userId:  fieldType: "trimmedString", required: true
      postId:  fieldType: "trimmedString", required: false

  test "linked objects get converted to ids for writing", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter new LinkFieldsFilter fields =
        user: link: "user", required: true

    pipelines.myPipeline.create
      user: id: "abc123", name: "George"
    .then (data) ->
      assert.eq data, userId: "abc123", id: "0"

  test "included fields work", ->
    createWithPostCreate class User extends SimplePipeline
      ;

    createWithPostCreate class PostPipeline extends SimplePipeline
      @filter new LinkFieldsFilter fields =
        user: link: "user", required: true, include: true

    pipelines.user.create
      name: "George"
    .then (user) ->
      assert.eq user, name: "George", id: "0"
      pipelines.postPipeline.create user: user, message: "hi there!"
    .then (post) ->
      assert.eq post, userId: "0", id: "0", message: "hi there!"
      pipelines.postPipeline.get "0"
    .then (post) ->
      assert.eq post, userId: "0", id: "0", message: "hi there!", user: name: "George", id: "0"
