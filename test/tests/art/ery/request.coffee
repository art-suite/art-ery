{log} = require 'art-foundation'
{Request, Pipeline} = require 'art-ery'

suite "Art.Ery.Request Validation", ->
  test "new Request - invalid", ->
    assert.throws -> new Request

  test "new Request action: 'get' - valid", ->
    new Request
      action: "get"
      key: "123"
      pipeline: new Pipeline
      session: {}

  test "new Request action: 'get' - invalid", ->
    assert.throws -> new Request
      action: "get"
      key: "123"
      pipeline: new Pipeline
      session: {}
      data: {}

  test "new Request action: 'create' - valid", ->
    new Request
      action: "create"
      pipeline: new Pipeline
      session: {}
      data: {}

  test "new Request action: 'create' - invalid", ->
    assert.throws -> new Request
      action: "create"
      key: "123"
      pipeline: new Pipeline
      session: {}
      data: {}

  test "new Request action: 'update' - valid", ->
    new Request
      action: "update"
      key: "123"
      pipeline: new Pipeline
      session: {}
      data: {}

  test "new Request action: 'delete' - valid", ->
    new Request
      action: "delete"
      key: "123"
      pipeline: new Pipeline
      session: {}

  test "new Request action: 'delete' - invalid", ->
    assert.throws -> new Request
      action: "delete"
      key: "123"
      pipeline: new Pipeline
      session: {}
      data: {}

suite "Art.Ery.Request properties", ->
  test "getKey", ->
    request = new Request
      action: "get"
      key: "123"
      pipeline: new Pipeline
      session: {}
    assert.eq request.getKey(), "123"

suite "Art.Ery.Request withData", ->
  test "withData", ->
    request = new Request
      action: "create"
      pipeline: new Pipeline
      session: {}
      data: {}
    request.withData foo: "bar"
    .then (newRequest) ->
      assert.neq newRequest, request
      assert.eq newRequest.data, foo: "bar"

  test "withMergedData", ->
    request = new Request
      action: "create"
      pipeline: new Pipeline
      session: {}
      data: bing: "bong"
    request.withMergedData foo: "bar"
    .then (newRequest) ->
      assert.neq newRequest, request
      assert.eq newRequest.data, bing: "bong", foo: "bar"
