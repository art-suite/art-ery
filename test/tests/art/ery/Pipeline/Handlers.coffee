{log, createWithPostCreate} = require 'art-foundation'
{missing, Pipeline} = Neptune.Art.Ery

module.exports = suite: ->
  test "basic", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers foo: (request) -> foo: 1, bar: 2

    p = new MyPipeline
    log filters: p.filters
    assert.eq p.filters.length, 1
    p.foo()
    .then (data) ->
      assert.eq data, foo: 1, bar: 2

  test "two handlers calls, one filter", ->
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers foo: (request) -> {}
      @handlers bar: (request) -> {}

    p = new MyPipeline
    log filters: p.filters
    assert.eq p.filters.length, 1
