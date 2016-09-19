{log, createWithPostCreate, isString, Validator, Promise} = require 'art-foundation'
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
      data: user: id: "abc123", name: "George"
    .then (data) ->
      assert.eq data, userId: "abc123", id: "0"

  test "autoCreate linked object triggers on writing", ->
    createWithPostCreate class Media extends SimplePipeline
      ;

    createWithPostCreate class Post extends SimplePipeline
      @filter new LinkFieldsFilter fields =
        media: link: required: autoCreate: true

    pipelines.post.create
      data: media: url: url = "bar.com/foo"

    .then (data) ->
      assert.eq data, mediaId: "0", id: "0"
      pipelines.media.get key: "0"

    .then (media) ->
      assert.eq media.url. url

  test "included fields work (basic)", ->
    createWithPostCreate class User extends SimplePipeline
      ;

    createWithPostCreate class PostPipeline extends SimplePipeline
      @filter new LinkFieldsFilter fields =
        user: include: required: link: true

    pipelines.user.create
      data: name: "George"
    .then (user) ->
      assert.eq user, name: "George", id: "0"
      pipelines.postPipeline.create data: user: user, message: "hi there!"
    .then (post) ->
      assert.eq post, userId: "0", id: "0", message: "hi there!"
      pipelines.postPipeline.get key: "0"
    .then (post) ->
      assert.eq post, userId: "0", id: "0", message: "hi there!", user: name: "George", id: "0"

  test "included fields works on record-array-results", ->
    createWithPostCreate class User extends SimplePipeline
      ;

    userId1 = null
    userId2 = null
    createWithPostCreate class PostPipeline extends SimplePipeline
      @handler
        getSampleData: (request) ->
          [
            {userId: userId1, message: "Hi!"}
            {userId: userId2, message: "Howdy!"}
          ]
      @filter new LinkFieldsFilter
        user: link: "user", required: true, include: true

    Promise.all([
      pipelines.user.create(data: name: "George").then (user) -> userId1 = user.id
      pipelines.user.create(data: name: "Frank" ).then (user) -> userId2 = user.id
    ])
    .then (post) -> pipelines.postPipeline.getSampleData()
    .then (post) ->
      assert.eq post, [
        {
          userId:  "0"
          message: "Hi!"
          user:    name: "George", id: "0"
        },{
          userId:  "1"
          message: "Howdy!"
          user:    name: "Frank", id: "1"
        }
      ]
