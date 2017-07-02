{defineModule, log} = require 'art-standard-lib'
Filter = require '../Filter'
Uuid = require 'uuid'
{FieldTypes} = require 'art-validation'

defineModule module, class UuidFilter extends Filter
  @alwaysForceNewIds: true
  @before
    create: (request) ->
      request.withMergedData
        id: if UuidFilter.alwaysForceNewIds
            Uuid.v4()
          else
            request.data.id || Uuid.v4()

  @fields
    id: FieldTypes.id
