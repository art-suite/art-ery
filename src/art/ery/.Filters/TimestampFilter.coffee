{defineModule, log, Validator, m} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class TimestampFilter extends Filter
  @before
    create: (request) ->
      request.withMergedData m
        createdAt: now = Date.now()
        updatedAt: now
        # use existing values, if present
        request.data if request.originatedOnServer


    update: (request) ->
      request.withMergedData
        updatedAt: Date.now()
        # use existing values, if present
        request.data if request.originatedOnServer

  @fields
    createdAt: Validator.fieldTypes.timestamp
    updatedAt: Validator.fieldTypes.timestamp
