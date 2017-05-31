{log, merge, CommunicationStatus} = require 'art-foundation'
{Response, Request, Pipeline} = Neptune.Art.Ery
{success, failure, missing} = CommunicationStatus

newRequest = (options)->
  new Request merge
    type: "create"
    pipeline: new Pipeline
    session: {}
    options

newResponse = (responseOptions, requestOptions)->
  new Response merge
    status: success
    request: newRequest requestOptions
    responseOptions

module.exports = suite:
  "new Response validation":
    invalid: ->
      test "without request or status ", ->
        assert.throws -> new Response {}

      test "without status", ->
        assert.throws -> new Response request: newRequest()

      test "without request", ->
        assert.throws -> new Response status: success

      test "props is not an object", ->
        assert.throws -> new Response
          props: 123
          status: success
          request: newRequest()

      test "invalid status", ->
        assert.throws -> new Response
          status: "dode"
          request: newRequest()

      test "invalid session", ->
        assert.throws -> newResponse session: 123

    valid: ->

      test "status: success", ->
        new Response
          status: success
          request: newRequest()

      test "status: failure", ->
        new Response
          status: failure
          request: newRequest()

      test "status: missing", ->
        new Response
          status: missing
          request: newRequest()

  getters: ->
    test "request", -> assert.instanceof Request, newResponse().request
    test "requestData",   -> r = newResponse(props: foo: 1, data: bar: 2); assert.equal r.request.data, r.requestData
    test "requestProps",  -> r = newResponse(props: foo: 1, data: bar: 2); assert.equal r.request.props, r.requestProps
    test "responseProps", -> r = newResponse(props: foo: 1, data: bar: 2); assert.equal r.props, r.responseProps; assert.neq r.props, r.requestProps
    test "responseData",  -> r = newResponse(props: foo: 1, data: bar: 2); assert.equal r.data,  r.responseData;  assert.neq r.data, r.requestData
    test "parentRequest", -> assert.eq undefined, newResponse().parentRequest
    test "rootRequest", ->
      response = newResponse()
      assert.eq response.request, response.rootRequest

  props: ->
    test "props defaults to {}", ->
      assert.selectedPropsEq
        props: {}
        new Response
          status: success
          request: newRequest()

    test "props: myProp: 123", ->
      assert.selectedPropsEq
        props: myProp: 123
        new Response
          status: success
          props: myProp: 123
          request: newRequest()

    test "data: 123 sets props", ->
      assert.selectedPropsEq
        props: data: 123
        _data: undefined
        data: 123

        new Response
          status: success
          data: 123
          request: newRequest()

    test "data: 123, props: data: 456 - data-outside-props-has-priority", ->
      assert.selectedPropsEq
        props: data: 123

        new Response
          status: success
          data: 123
          props: data: 456
          request: newRequest()

  plainObjectsResponse: ->
    test "basic", ->
      assert.eq
        status: "success"
        newResponse().plainObjectsResponse

    test "data: 123", ->
      assert.eq
        status: "success"
        props: data: 123
        newResponse(data: 123).plainObjectsResponse

    test "session: 123", ->
      assert.eq
        status: "success"
        session: userId: "abc123"
        newResponse(session: userId: "abc123").plainObjectsResponse

    test "props: foo: 123", ->
      assert.eq
        status: "success"
        props: foo: 123
        newResponse(props: foo: 123).plainObjectsResponse
