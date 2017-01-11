{log, formattedInspect} = require 'art-foundation'
{Request, Pipeline} = Neptune.Art.Ery

module.exports = suite:
  validation: ->
    test "new Request - invalid", ->
      assert.throws -> new Request

    test "new Request - missing session", ->
      assert.throws ->
        new Request
          type: "get"
          key: "123"
          pipeline: new Pipeline

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
      assert.eq formattedInspect(request),   """
        Neptune.Art.Ery.Request:
          pipeline: pipeline, type: "get", key: "123", session: {}, subrequestCount: 0

        """

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

  properties: ->
    test "getKey", ->
      request = new Request
        type: "get"
        key: "123"
        pipeline: new Pipeline
        session: {}
      assert.eq request.getKey(), "123"

  withData: ->
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

  derivedRequestsPersistProps: ->
    test "originatedOnServer", ->
      r = new Request
        type: "get"
        key: "123"
        originatedOnServer: true
        pipeline: new Pipeline
        session: {}

      assert.eq r.originatedOnServer, true
      assert.eq r.props.originatedOnServer, true
      r.withData({}).then (r2) ->
        assert.eq r2.originatedOnServer, true
