{log, Validator, defineModule} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class UserOwnedFilter extends Filter
  @before
    create: (request) ->
      request.withMergedData
        userId: request.data.userId || request.session.userId
