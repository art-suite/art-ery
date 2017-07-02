{defineModule, log, merge} = require 'art-standard-lib'
{Pipeline, KeyFieldsMixin, AfterEventsFilter, UniqueIdFilter} = Neptune.Art.Ery

defineModule module, class MemStorePipeline extends KeyFieldsMixin Pipeline
  @abstractClass()

  constructor: ->
    super
    @_store = {}

  @getter "store"

  @filter UniqueIdFilter
  @filter AfterEventsFilter

  @handlers
    get: ({key}) -> @_store[key]
    create: (request) -> @_store[request.data.id] = request.data
    update: ({data, key}) -> @_store[key] = merge @_store[key], data, updateCount: (@_store[key]?.updateCount || 0) + 1
    delete: ({key}) -> delete @_store[key]
