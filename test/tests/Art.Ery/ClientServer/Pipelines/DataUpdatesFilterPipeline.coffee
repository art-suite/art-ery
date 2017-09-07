{isString, defineModule, array, randomString, merge, log, formattedInspect} = require 'art-foundation'
{Pipeline, KeyFieldsMixin, DataUpdatesFilter} = require 'art-ery'

defineModule module, class DataUpdatesFilterPipeline extends require './SimpleStore'

  @remoteServer "http://localhost:8085"

  fluxLog = []
  @fluxModelMixin (superClass) ->
    class DataUpdatesFilterFluxModelMixin extends superClass
      dataUpdated: (key, data) -> fluxLog.push(dataUpdated: {model: @name, key, data});super
      dataDeleted: (key, data) -> fluxLog.push(dataDeleted: {model: @name, key, data});super

  @filter DataUpdatesFilter

  @filter
    before:
      create: (request) ->
        request.withMergedData createdAt: 123, updatedAt: 123

      update: (request) ->
        request.withMergedData updatedAt: 321

  @filter
    location: "client"
    before: reset: (request) ->
      fluxLog = []
      request

  @getter fluxLog: -> fluxLog

  @query
    userByEmail:
      query: ({key}) -> array @db, when: (v, k) -> v.email == key
      dataToKeyString: ({email}) -> email

  @publicRequestTypes "subrequestTest"

  @handlers
    subrequestTest: (request) ->
      {key, data, type} = request.data
      request.require isString(type), "subrequestTest needs a request-type"
      .then ->
        log subrequestTest: {key, data, type}
        request.subrequest request.pipelineName, type, {key, data}
