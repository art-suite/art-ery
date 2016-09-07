{log, Validator} = require 'art-foundation'
Filter = require '../Filter'
Uuid = require 'uuid'

module.exports = class UuidFilter extends Filter
  @alwaysForceNewIds: true
  @before
    create: (request) ->
      request.withMergedData
        id: if UuidFilter.alwaysForceNewIds
            Uuid.v4()
          else
            request.data.id || Uuid.v4()

  @fields
    id: Validator.fieldTypes.id
