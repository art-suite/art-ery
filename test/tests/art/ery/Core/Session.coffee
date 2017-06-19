{log} = require 'art-standard-lib'
{Response, Request, Pipeline, Session} = Neptune.Art.Ery

module.exports = suite: ->
  test 'singleton', ->
    Session.singleton.data = userId: 'abc'
    assert.eq Session.singleton.data, userId: 'abc'

  test "new Session", ->
    s = new Session
    assert.eq s._data, s.data
    assert.eq s.data, {}

  test "new Session userId: '123'", ->
    s = new Session userId: '123'
    assert.eq s.data, userId: '123'

  test "session.data = foo: 'bar'", ->
    s = new Session userId: '123'
    assert.eq s.data, userId: '123'
    s.data = foo: 'bar'
    assert.eq s.data, foo: 'bar'
    assert.eq s._data, s.data

  test "change event", (done) ->
    s = new Session userId: '123'
    s.on change: ({props}) ->
      assert.eq props, data: userId: '456'
      done()

    s.data = userId: '456'
