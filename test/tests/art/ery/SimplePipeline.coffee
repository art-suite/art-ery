Foundation = require 'art-foundation'
Ery = Neptune.Art.Ery

{merge, log, CommunicationStatus, wordsArray} = Foundation
{missing} = CommunicationStatus
{Pipeline, Filter} = Ery

module.exports = class SimplePipeline extends Pipeline

  @suite: ->
    test "clientApiMethodList", ->
      simplePipeline = new SimplePipeline
      assert.eq simplePipeline.clientApiMethodList, wordsArray "get create update delete"

    test "get -> missing", ->
      simplePipeline = new SimplePipeline
      simplePipeline.get "doesn't exist"
      .then (response) -> throw new Error "shouldn't succeed"
      .catch (response) ->
        assert.eq response.status, missing

    test "update -> missing", ->
      simplePipeline = new SimplePipeline
      simplePipeline.update "doesn't exist"
      .then (response) -> throw new Error "shouldn't succeed"
      .catch (response) ->
        assert.eq response.status, missing

    test "delete -> missing", ->
      simplePipeline = new SimplePipeline
      simplePipeline.delete "doesn't exist"
      .then (response) -> throw new Error "shouldn't succeed"
      .catch (response) ->
        assert.eq response.status, missing

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

  constructor: ->
    super
    @_store = {}
    @_nextUniqueKey = 0

  @getter
    nextUniqueKey: ->
      @_nextUniqueKey++ while @_store[@_nextUniqueKey]
      (@_nextUniqueKey++).toString()

  @handlers
    get: ({key}) ->
      @_store[key]

    create: (request) ->
      {nextUniqueKey} = @
      @_store[nextUniqueKey] = merge request.data, key: nextUniqueKey

    update: ({key, data}) ->
      if previousData = @_store[key]
        @_store[key] = merge previousData, data

    delete: ({key}) ->
      if previousData = @_store[key]
        @_store[key] = null
        previousData
