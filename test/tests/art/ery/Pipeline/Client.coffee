{log} = require 'art-foundation'
{missing} = require 'art-ery'
SimplePipeline = require '../SimplePipeline'

module.exports = suite: ->
  test "get -> missing", ->
    simplePipeline = new SimplePipeline
    simplePipeline.get "doesn't exist"
    .then (response) -> throw new Error "shouldn't succeed"
    .catch (response) -> assert.eq response.status, missing

  test "create returns new record", ->
    simplePipeline = new SimplePipeline
    simplePipeline.create foo: "bar"
    .then (data) -> assert.eq data, foo: "bar", key: "0"

  test "create -> get", ->
    simplePipeline = new SimplePipeline
    simplePipeline.create foo: "bar"
    .then ({key}) -> simplePipeline.get key
    .then (data) -> assert.eq data, foo: "bar", key: "0"

  test "create -> update", ->
    simplePipeline = new SimplePipeline
    simplePipeline.create foo: "bar"
    .then ({key}) -> simplePipeline.update key, fooz: "baz"
    .then (data) -> assert.eq data, foo: "bar", fooz: "baz", key: "0"

  test "create -> delete", ->
    simplePipeline = new SimplePipeline
    simplePipeline.create foo: "bar"
    .then ({key}) -> simplePipeline.delete key
    .then ({key}) -> simplePipeline.get key
    .then (response) -> throw new Error "shouldn't succeed"
    .catch (response) -> assert.eq response.status, missing
