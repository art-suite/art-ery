{log, isString, Validator} = require 'art-foundation'
{Pipeline, Filters} = Neptune.Art.Ery
{LinkFieldsFilter} = Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "fields are set correctly", ->
    simplePipeline = new SimplePipeline()
    .filter new LinkFieldsFilter fields =
      user: linkTo: "user", required: true
      post: linkTo: "post"

    assert.eq simplePipeline.fields,
      userId:  type: "trimmedString", required: true
      postId:  type: "trimmedString", required: false

  test "linked objects get converted to ids for writing", ->
    simplePipeline = new SimplePipeline()
    .filter new LinkFieldsFilter fields =
      user: linkTo: "user", required: true

    simplePipeline.create
      user: id: "abc123", name: "George"
    .then (data) ->
      assert.eq data, userId: "abc123", id: "0"

  test "included fields work", ->
    Pipeline.addNamedPipeline "user", userPipeline = new SimplePipeline()

    postPipeline = new SimplePipeline()
    .filter new LinkFieldsFilter fields =
      user: linkTo: "user", required: true, include: true

    userPipeline.create
      name: "George"
    .then (user) ->
      assert.eq user, name: "George", id: "0"
      postPipeline.create user: user, message: "hi there!"
    .then (post) ->
      assert.eq post, userId: "0", id: "0", message: "hi there!"
      postPipeline.get "0"
    .then (post) ->
      assert.eq post, userId: "0", id: "0", message: "hi there!", user: name: "George", id: "0"
