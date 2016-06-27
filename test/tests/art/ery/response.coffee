{log} = require 'art-foundation'
{Response, Request, Artery, success, failure} = require 'art-ery'

suite "Art.Ery.Response Validation", ->
  test "new Response - invalid", ->
    assert.throws -> new Response {}

  test "new Response - success - valid", ->
    new Response
      status: success
      request: new Request
        action: "create"
        artery: new Artery
        session: {}
        data: {}
      data: {}

  test "new Response - success - invalid", ->
    assert.throws -> new Response
      status: success
      request: new Request
        action: "create"
        artery: new Artery
        session: {}
        data: {}

  test "new Response - failure - valid", ->
    new Response
      status: failure
      request: new Request
        action: "create"
        artery: new Artery
        session: {}
        data: {}
      error: {}

  test "new Response - failure - invalid", ->
    assert.throws -> new Response
      status: failure
      request: new Request
        action: "create"
        artery: new Artery
        session: {}
        data: {}
