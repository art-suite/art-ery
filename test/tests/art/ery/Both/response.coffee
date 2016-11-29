{log, CommunicationStatus} = require 'art-foundation'
{Response, Request, Pipeline} = Neptune.Art.Ery
{success, failure, missing} = CommunicationStatus

module.exports = suite: validation: ->
  test "new Response - invalid", ->
    assert.throws -> new Response {}

  test "new Response - invalid", ->
    assert.throws -> new Response
      request: new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: {}

  test "new Response - success - valid", ->
    new Response
      status: success
      request: new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: {}

  test "new Response - failure - valid", ->
    new Response
      status: failure
      request: new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: {}

  test "new Response - missing - valid", ->
    new Response
      status: missing
      request: new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: {}

  test "new Response - invalid status", ->
    assert.throws -> new Response
      status: "dode"
      request: new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: {}



