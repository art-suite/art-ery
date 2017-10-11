{log, object, w, defineModule, isPlainObject, isString, each, Promise} = require 'art-standard-lib'
{Validator} = require 'art-validation'
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
    {@userUpdatableFields, @userCreatableFields, @publicFields} = options || {}
    @group = "outter"

  @getter "userUpdatableFields userCreatableFields publicFields"

  normallyPublicFields = w "id userId createdAt updatedAt"

  expandPossiblyLinkedFields = (fields) ->
    for name, value in fields when name.match /Id$/
      [root] = name.split /Id$/
      fields[root] = value unless fields[root]?
    fields

  @setter
    publicFields: (fieldString) ->
      return @_publicFields = true if fieldString == true

      @_publicFields = pfs = if isPlainObject fieldString
        fieldString
      else if isString fieldString
        object w(fieldString), with: -> true
      else {}

      each normallyPublicFields, (field) -> pfs[field] = true unless pfs[field] == false
      expandPossiblyLinkedFields pfs

    userUpdatableFields: (fieldString) ->
      @_userUpdatableFields = expandPossiblyLinkedFields if isPlainObject fieldString
        fieldString
      else if isString fieldString
        object w(fieldString), with: -> true
      else {}

    userCreatableFields: (fieldString) ->
      @_userCreatableFields = expandPossiblyLinkedFields if isPlainObject fieldString
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

  @after
    all: (response) ->
      return response if response.originatedOnServer || @publicFields == true
      {userId} = response.session
      allowedFields = @publicFields

      response.withTransformedRecords
        when: (record) -> response.pipeline.isRecord(record) && record.userId != userId
        with: (record) ->
          keyCount = 0
          filteredRecord = object record,
            when: (v, k) -> allowedFields[k]
            with: (v, k) -> keyCount++; v
          log {filteredRecord, record, type: response.type}
          if keyCount > 0 then filteredRecord