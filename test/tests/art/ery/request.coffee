{log, formattedInspect} = require 'art-foundation'
{Request, Pipeline} = require 'art-ery'

suite "Art.Ery.Request.Validation", ->
  test "new Request - invalid", ->
    assert.throws -> new Request

  test "new Request type: 'get' - valid", ->
    new Request
      type: "get"
      key: "123"
      pipeline: new Pipeline
      session: {}

  test "formattedInspect new Request", ->
    request = new Request
      type: "get"
      key: "123"
      pipeline: new Pipeline
      session: {}
    log
      inspectedObjects: request.inspectedObjects
    log formattedInspect(request)
    assert.eq formattedInspect(request), ""

  test "new Request type: 'create' - valid", ->
    new Request
      type: "create"
      pipeline: new Pipeline
      session: {}
      data: {}

  test "new Request type: 'update' - valid", ->
    new Request
      type: "update"
      key: "123"
      pipeline: new Pipeline
      session: {}
      data: {}

  test "new Request type: 'delete' - valid", ->
    new Request
      type: "delete"
      key: "123"
      pipeline: new Pipeline
      session: {}

suite "Art.Ery.Request.properties", ->
  test "getKey", ->
    request = new Request
      type: "get"
      key: "123"
      pipeline: new Pipeline
      session: {}
    assert.eq request.getKey(), "123"

suite "Art.Ery.Request.withData", ->
  test "withData", ->
    request = new Request
      type: "create"
      pipeline: new Pipeline
      session: {}
      data: {}
    request.withData foo: "bar"
    .then (newRequest) ->
      assert.neq newRequest, request
      assert.eq newRequest.data, foo: "bar"

  test "withMergedData", ->
    request = new Request
      type: "create"
      pipeline: new Pipeline
      session: {}
      data: bing: "bong"
    request.withMergedData foo: "bar"
    .then (newRequest) ->
      assert.neq newRequest, request
      assert.eq newRequest.data, bing: "bong", foo: "bar"
