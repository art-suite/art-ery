{log, Validator} = require 'art-foundation'
Filter = require '../Filter'
Uuid = require 'uuid'

module.exports = class UuidFilter extends Filter
  @before
    create: (request) ->
      request.withMergedData
        id: Uuid.v4()

  @fields
    id: Validator.fieldTypes.id
