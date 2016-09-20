{defineModule, log, Validator} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class TimestampFilter extends Filter
  @before
    create: (request) ->
      request.withMergedData
        createdAt: now = Date.now()
        updatedAt: now

    update: (request) ->
      request.withMergedData
        updatedAt: Date.now()

  @fields
    createdAt: Validator.fieldTypes.timestamp
    updatedAt: Validator.fieldTypes.timestamp
