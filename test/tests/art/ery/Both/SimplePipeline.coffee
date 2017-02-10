Foundation = require 'art-foundation'
Ery = Neptune.Art.Ery

{merge, log, createWithPostCreate, CommunicationStatus, wordsArray} = Foundation
{missing} = CommunicationStatus
{Pipeline, Filter} = Ery

module.exports = createWithPostCreate class SimplePipeline extends Pipeline

  @suite: ->
    test "clientApiMethodList", ->
      simplePipeline = new SimplePipeline
      assert.eq simplePipeline.clientApiMethodList, wordsArray "reset get create update delete"

    test "get -> missing", ->
      simplePipeline = new SimplePipeline
      assert.rejects simplePipeline.get "doesn't exist"
      .then ({info:{response}}) -> assert.eq response.status, missing

    test "update -> missing", ->
      simplePipeline = new SimplePipeline
      assert.rejects simplePipeline.update "doesn't exist"
      .then ({info:{response}}) -> assert.eq response.status, missing

    test "delete -> missing", ->
      simplePipeline = new SimplePipeline
      assert.rejects simplePipeline.delete "doesn't exist"
      .then ({info:{response}}) -> assert.eq response.status, missing

    test "create returns new record", ->
      simplePipeline = new SimplePipeline
      simplePipeline.create data: foo: "bar"
      .then (data) -> assert.eq data, foo: "bar", id: "0"

    test "create -> get string", ->
      simplePipeline = new SimplePipeline
      simplePipeline.create data: foo: "bar"
      .then ({id}) -> simplePipeline.get key: id
      .then (data) -> assert.eq data, foo: "bar", id: "0"

    test "create -> get key: string", ->
      simplePipeline = new SimplePipeline
      simplePipeline.create data: foo: "bar"
      .then ({id}) -> simplePipeline.get key: id
      .then (data) -> assert.eq data, foo: "bar", id: "0"

    test "create -> update", ->
      simplePipeline = new SimplePipeline
      simplePipeline.create data: foo: "bar"
      .then ({id}) -> simplePipeline.update key: id, data: fooz: "baz"
      .then (data) -> assert.eq data, foo: "bar", fooz: "baz", id: "0"

    test "create -> delete", ->
      simplePipeline = new SimplePipeline
      p = simplePipeline.create data: foo: "bar"
      .then ({id}) -> simplePipeline.delete key: id
      .then ({id}) -> simplePipeline.get key: id
      assert.rejects p
      .then ({info:{response}}) -> assert.eq response.status, missing

  constructor: ->
    super
    @_store = {}
    @_nextUniqueKey = 0

  @getter
    nextUniqueKey: ->
      @_nextUniqueKey++ while @_store[@_nextUniqueKey]
      (@_nextUniqueKey++).toString()

  @handlers
    reset: ({data}) ->
      @_store = data || {}
      {}

    get: ({key}) ->
      @_store[key]

    create: ({data}) ->
      data = if data.id
        data
      else
        merge data, id: @nextUniqueKey

      @_store[data.id] = data

    update: ({key, data}) ->
      if previousData = @_store[key]
        @_store[key] = merge previousData, data

    delete: ({key}) ->
      if previousData = @_store[key]
        @_store[key] = null
        previousData
