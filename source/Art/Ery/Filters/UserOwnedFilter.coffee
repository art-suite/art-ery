{log, Validator, defineModule} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class UserOwnedFilter extends Filter
  @location: "server"

  @isOwner: isOwner = (request, data) ->
    {userId} = request.session
    data ||= request.data
    userId && userId == data?.userId

  @ownershipInfo: ownershipInfo = (request, data) ->
    {userId} = request.session
    data ||= request.data
    "(you are #{userId}, record owner is #{data?.userId})"

  @before
    # ensure we are setting userId to session.userId and session.userId is set
    # (unless reuest.originatedOnServer)
    create: (request) ->
      request.withMergedData userId: request.data.userId || request.session.userId
      .then (requestWithUserId) ->
        requestWithUserId.requireServerOriginOr isOwner(requestWithUserId), "to create a record you do not own #{ownershipInfo request}"

    # ensure updates don't modify the userId
    # ensure the current user can only update their own records
    # (unless request.originatedOnServer)
    update: (request) ->
      {key} = request

      request.requireServerOriginOr !request.data?.userId || isOwner(request), "to change a record's owner #{ownershipInfo request}"
      .then ->
        if request.originatedOnServer
          # gets a free pass
          request
        else
          # TODO the new ArtEryAws lets us do this check during update: conditionExpression: userId: request.session.userId
          request.pipeline.get key: key
          .then (currentRecord) ->
            request.requireServerOriginOr isOwner(request, currentRecord), "to update a record you do not own #{ownershipInfo request}"

