{log, createWithPostCreate} = require 'art-foundation'
{missing, Pipeline} = Neptune.Art.Ery

module.exports = suite: ->
  setup ->
    Neptune.Art.Ery.config.location = "both"
    Neptune.Art.Ery.PipelineRegistry._reset()

  teardown ->
    Neptune.Art.Ery.config.location = "client"

  test "basic", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers foo: (request) -> foo: 1, bar: 2

    p = new MyPipeline
    assert.eq p.filters.length, 0
    p.foo()
    .then (data) ->
      assert.eq data, foo: 1, bar: 2

  test "return string", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers foo: (request) -> "my string"

    (new MyPipeline)
    .foo().then (data) -> assert.eq data, "my string"

  test "two handlers calls, one filter", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers foo: (request) -> {}
      @handlers bar: (request) -> {}

    p = new MyPipeline
    assert.eq p.filters.length, 0

  test "query handlers", ->
    createWithPostCreate class Post extends Pipeline
      @query postByUserId: (request) ->
        [request.key, 1, 2, 3]

    assert.eq Post.post.clientApiMethodList, ["postByUserId"]
    Post.post.postByUserId key: "foo"
    .then (results) ->
      assert.eq results, ["foo", 1, 2, 3]

  test "query handlers with after-all filter", ->
    createWithPostCreate class Post extends Pipeline
      @query postByUserId: (request) ->
        [request.key, 1, 2, 3]

      @filter
        after: all: (response) ->
          response.withData ("#{a} #{a}" for a in response.data)

    assert.eq Post.post.clientApiMethodList, ["postByUserId"]
    Post.post.postByUserId key: "foo"
    .then (results) ->
      assert.eq results, ["foo foo", "1 1", "2 2", "3 3"]
