{
  timeout, array, timeout, isPlainObject, formattedInspect, each, wordsArray, log, defineModule, merge, isString, shallowClone, isPlainArray, Promise
} = require 'art-standard-lib'
Filter = require '../Filter'
{normalizeFieldProps} = require 'art-validation'
{missing,networkFailure} = require 'art-communication-status'

defineModule module, class LinkFieldsFilter extends require './ValidationFilter'
  @location "server"

  ###
  IN:
    fields:
      # object mapping the linked fields (not the ID fields for those linked fileds)
      # EX:
      user:
          # any art-validation legal field description
          # Additional options:
          autoCreate:   true/false
            if set, when request-type == "create"
              if this field is set with an object without and id
                then it will FIRST create the linked-to-object
                then it will set the id-field with the linked-to-object

            if this field is set with an object WITH an id
              (I think this applies to both create and update request-types)
              will automatically set the id-field to the matching id

          pipelineName: string
            override the default pipelineName
            default: field-name (in this example: 'user')

          include: true/false
            if true, then when returning instances of this object, it will also
            fetch the linked field's object. In this case, it will set 'user' to
            the value returned from: pipelines.user.get userId
            (This is how it is actually fetched: request.cachedGet 'user', userId)

  ###
  constructor: (options) ->

    fields = {}
    @_linkFields = LinkFieldsFilter.normalizeLinkFields options.fields
    for fieldName, fieldProps of @_linkFields
      props = merge fieldProps, fieldType:  "trimmedString"
      delete props.idFieldName
      fields[fieldProps.idFieldName] = normalizeFieldProps props

    super merge options, {fields}

  # returns a new request
  preprocessRequest: (request) ->
    # empty updates or creates are possible, and that's OK
    # for example, add: or setDefault: values may be specified for updates.
    {type, pipeline, data = {}, session} = request

    ###
    Pass includedData from the requestProps to the ultimate responseProps.
    IncludedData is removed from 'data' so it isn't writen in this pipeline's record, but instead,
    if autoCreate/vivifiy is true, it is written to its own pipeline and linked in.

    postIncludeLinkedFieldData allows us to return the includedData in the response without
    re-reading the data back with additional requests.
    ###
    postIncludeLinkedFieldData = null

    processedData = merge data
    Promise.all array @_linkFields,
      when: ({idFieldName}, fieldName) -> !data[idFieldName] && data[fieldName]
      with: ({idFieldName, autoCreate, pipelineName}, fieldName, __, linkedFieldData) =>
        Promise.then =>
          if linkedFieldData.id then linkedFieldData
          else if autoCreate    then request.subrequest pipelineName, "create", data: linkedFieldData
          else                  throw new Error "New record-data provided for #{fieldName}, but autoCreate is not enabled for this field. #{fieldName}: #{formattedInspect linkedFieldData}"
        .then (linkedFieldData) =>
          (postIncludeLinkedFieldData||={})[fieldName] = linkedFieldData
          processedData[idFieldName] = linkedFieldData.id
          delete processedData[fieldName]
    .then -> request.with data: processedData, props: merge request.props, postIncludeLinkedFieldData && {postIncludeLinkedFieldData}

  booleanProps = wordsArray "link required include autoCreate"
  @normalizeLinkFields: (linkFields) ->
    each linkFields, lf = {}, (fieldProps, fieldName) ->
      {link, include, required, autoCreate} = normalizeFieldProps fieldProps
      if link
        lf[fieldName] = props =
          pipelineName: if isString link then link else fieldName
          idFieldName:  fieldName + "Id"
        props.autoCreate = true if autoCreate
        props.include =    true if include
        props.required =   true if required


  # OUT: promise.then -> new data
  includeLinkedFields: (response, data) ->
    {requestData, requestProps:{postIncludeLinkedFieldData}} = response

    # Right now we are going to always include unless explicitly set to false.
    # I like the semantic that we only auto-include root requests, but OBVIOUSLY,
    # that needs to apply to recursive-gets DUE TO AUTO-INCLUDE!
    # Which means we effectively need a special cachedGet for "auto-include-gets".
    # That's a little ugly, so I'm just doing the expedient solution - that is forward compatible.
    # It's just less efficient until I find a better way to implement this.
    requestIncludeProp = (response.rootRequest.props.include != false && response.requestProps.include != false)

    linkedData = shallowClone data
    promises = for fieldName, {idFieldName, pipelineName, include} of @_linkFields when include && id = linkedData[idFieldName]
      do (id, fieldName, idFieldName, pipelineName, include) =>
        Promise.then attemptGetLinkedField = =>
          if linkData = requestData?[fieldName] || postIncludeLinkedFieldData?[fieldName]
            merge {id}, linkData
          else if requestIncludeProp
            response.cachedGet pipelineName, id

        .catch (response) ->
          switch response.status
            when networkFailure
              # attempt retry once
              timeout 20 + 10 * Math.random()
              .then attemptGetLinkedField

            when missing
              null

            else
              log.error "LinkFieldsFilter: error including #{fieldName}. #{idFieldName}: #{id}. pipelineName: #{pipelineName}. Error: #{response}", response.error
              null

        .catch (response) -> null
        .then (value) -> linkedData[fieldName] = value if value?

    Promise.all promises
    .then -> linkedData

  @before
    create: (request) -> @preprocessRequest(request).then (request) => @_validate "validateCreate", request
    update: (request) -> @preprocessRequest(request).then (request) => @_validate "validateUpdate", request

  # to support 'include' for query results, just alter this to be an 'after-all-requests'
  # and have it detect is data is an array
  # Idealy, we'd also use the bulkGet feature
  @after
    all: (response) ->
      return response if response.type == "delete"
      response.withTransformedRecords (record) =>
        @includeLinkedFields response, record
