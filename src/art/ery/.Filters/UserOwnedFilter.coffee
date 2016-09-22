{log, Validator, defineModule} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class UserOwnedFilter extends Filter
  @filterLocation: "server"

  @before
    # ensure we are setting userId to session.userId and session.userId is set
    # (unless reuest.originatedOnServer)
    create: (request) ->
      {data, session} = request

      unless session.userId && !data.userId
        request.requireServerOrigin "to create a record where data.userId != session.userId"

      request.withMergedData
        userId: data.userId || session.userId

    # ensure updates don't modify the userId
    # ensure the current user can only update their own records
    # (unless request.originatedOnServer)
    update: (request) ->
      {data, session} = request

      if data.userId
        request.requireServerOrigin "to update data.userId"

      @pipeline.get data.id
      .then (currentRecord) =>
        if session.userId != currentRecord.userId
          request.requireServerOrigin "to modify a record where currentRecord.userId != session.userId"
        request
