{isString, defineModule, array, randomString, merge, log} = require 'art-foundation'
{Pipeline, KeyFieldsMixin, DataUpdatesFilter} = require 'art-ery'

defineModule module, class DataUpdatesFilterPipeline extends KeyFieldsMixin Pipeline

  @remoteServer "http://localhost:8085"

  @filter DataUpdatesFilter

  @filter
    before:
      create: (request) ->
        request.withMergedData createdAt: 123, updatedAt: 123

      update: (request) ->
        request.withMergedData updatedAt: 321

  constructor: ->
    super
    @db = {}

  # @query
  #   pusherTestsByNoodleId:
  #     query: ({key}) -> array @db, when: (v, k) -> v.noodleId == key
  #     toKeyString: ({noodleId}) -> noodleId

  @handlers
    reset: ({data}) ->
      @db = data
      true

    get: ({key}) ->
      @db[key]

    create: (request) ->
      key = randomString().slice 0, 8
      @db[key] = merge request.data, id: key

    update: (request) ->
      {data, key} = request
      key ||= request.pipeline.toKeyString data
      return null unless @db[key]
      @db[key] = merge @db[key], data

    delete: (request) ->
      {key} = request
      key ||= request.pipeline.toKeyString data
      return null unless @db[key]
      out = @db[key]
      delete @db[key]
      out

    subrequestTest: (request) ->
      {key, data, type} = request.data
      request.require isString(type), "subrequestTest needs a request-type"
      .then ->
        log subrequestTest: {key, data, type}
        request.subrequest request.pipelineName, type, {key, data}
