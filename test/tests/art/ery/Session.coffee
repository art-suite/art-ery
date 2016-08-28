{log} = require 'art-foundation'
{Response, Request, Pipeline, Session, success, failure} = require 'art-ery'

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
