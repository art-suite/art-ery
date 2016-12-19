{log, Validator, defineModule} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class UserOwnedFilter extends Filter
  @location: "server"

  @before
    # ensure we are setting userId to session.userId and session.userId is set
    # (unless reuest.originatedOnServer)
    create: (request) ->
      {userId} = request.session

      {data} = request
      if data.userId && data.userId != userId
        request.requireServerOrigin "to create a record where data.userId != session.userId"
        userId = data.userId

      request.withMergedData {userId}

    # ensure updates don't modify the userId
    # ensure the current user can only update their own records
    # (unless request.originatedOnServer)
    update: (request) ->
      {data, session, key} = request

      if data.userId
        request.requireServerOrigin "to update data.userId"

      request.pipeline.get key: key
      .then (currentRecord) =>
        if session.userId != currentRecord.userId
          request.requireServerOrigin "to modify a record where currentRecord.userId(#{currentRecord.userId}) != session.userId(#{session.userId})"
        request
