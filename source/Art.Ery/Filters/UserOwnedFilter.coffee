{log, object, w, Validator, defineModule, isPlainObject, isString} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class UserOwnedFilter extends Filter

  @isOwner: isOwner = (request, data) ->
    {userId} = request.session
    data ||= request.data
    userId && userId == data?.userId

  @ownershipInfo: ownershipInfo = (request, data) ->
    {userId} = request.session
    data ||= request.data
    "(you are #{userId}, record owner is #{data?.userId})"

  constructor: (options) ->
    super
    {@userUpdatableFields, @userCreatableFields} = options || {}
    @group = "outter"

  @getter "userUpdatableFields userCreatableFields"
  @setter
    userUpdatableFields: (fieldString) ->
      @_userUpdatableFields = if isPlainObject fieldString
        fieldString
      else if isString fieldString
        object w(fieldString), with: -> true
      else {}

    userCreatableFields: (fieldString) ->
      @_userCreatableFields = if isPlainObject fieldString
        fieldString
      else if isString fieldString
        object w(fieldString), with: -> true
      else {}

      # userId is validated specially
      @_userCreatableFields.userId = true

  requireCanSetFields: requireCanSetFields = (request, allowedFields) ->
    unless request.originatedOnServer
      for k, v of request.data when !allowedFields[k]
        return Promise.resolve request.clientFailureNotAuthorized "not allowed to #{request.type} field: #{k}. allowedFields: #{Object.keys(allowedFields).join ', '}"
    Promise.resolve request

  @before
    # ensure we are setting userId to session.userId and session.userId is set
    # (unless reuest.originatedOnServer)
    create: (request) ->
      request.withMergedData userId: request.data?.userId || request.session.userId
      .then (requestWithUserId) ->
        requestWithUserId.requireServerOriginOr isOwner(requestWithUserId), "to create a record you do not own #{ownershipInfo request}"
      .then (request) => requireCanSetFields request, @userCreatableFields

    # ensure updates don't modify the userId
    # ensure the current user can only update their own records
    # (unless request.originatedOnServer)
    update: ownerOnlyFilter = (request) ->
      {key} = request

      request.requireServerOriginOr !request.data?.userId || isOwner(request), "to change a record's owner #{ownershipInfo request}"
      .then ->
        if request.originatedOnServer
          # gets a free pass
          request
        else
          # TODO the new ArtEryAws lets us do this check during update: conditionExpression: userId: request.session.userId
          request.cachedGet request.pipelineName, key
          .then (currentRecord) ->
            request.requireServerOriginOr isOwner(request, currentRecord), "to update a record you do not own #{ownershipInfo request}"
      .then (request) => requireCanSetFields request, @userUpdatableFields

    delete: ownerOnlyFilter