{log, CommunicationStatus} = require 'art-foundation'
{Response, Request, Pipeline} = Neptune.Art.Ery
{success, failure} = CommunicationStatus

module.exports = suite: validation: ->
  test "new Response - invalid", ->
    assert.throws -> new Response {}

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
      error: {}

  test "new Response - failure - invalid", ->
    assert.throws -> new Response
      status: failure
      request: new Request
        type: "create"
        pipeline: new Pipeline
        session: {}
        data: {}
