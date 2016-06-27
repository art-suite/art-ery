{log} = require 'art-foundation'
{missing} = require 'art-ery'
SimpleArtery = require './simple_artery'

suite "Art.Ery.Artery Client Basics", ->
  test "get -> missing", ->
    simpleArtery = new SimpleArtery
    simpleArtery.get "doesn't exist"
    .then (response) -> throw new Error "shouldn't succeed"
    .catch (response) -> assert.eq response.status, missing

  test "create returns new record", ->
    simpleArtery = new SimpleArtery
    simpleArtery.create foo: "bar"
    .then (data) -> assert.eq data, foo: "bar", key: "0"

  test "create -> get", ->
    simpleArtery = new SimpleArtery
    simpleArtery.create foo: "bar"
    .then ({key}) -> simpleArtery.get key
    .then (data) -> assert.eq data, foo: "bar", key: "0"

  test "create -> update", ->
    simpleArtery = new SimpleArtery
    simpleArtery.create foo: "bar"
    .then ({key}) -> simpleArtery.update key, fooz: "baz"
    .then (data) -> assert.eq data, foo: "bar", fooz: "baz", key: "0"

  test "create -> delete", ->
    simpleArtery = new SimpleArtery
    simpleArtery.create foo: "bar"
    .then ({key}) -> simpleArtery.delete key
    .then ({key}) -> simpleArtery.get key
    .then (response) -> throw new Error "shouldn't succeed"
    .catch (response) -> assert.eq response.status, missing
