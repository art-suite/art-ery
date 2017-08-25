{
  timeout, array, isPlainObject, formattedInspect, each, wordsArray, log, defineModule, merge, isString, shallowClone, isPlainArray, Promise
} = require 'art-standard-lib'
Filter = require '../Filter'
{normalizeFieldProps} = require 'art-validation'
{missing} = require 'art-communication-status'

defineModule module, class LinkFieldsFilter extends require './ValidationFilter'
  @location "server"

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

    if response.requestProps
      {include} = response.requestProps

    requestIncludeProp = if include == undefined then response.isRootRequest else !!include

    linkedData = shallowClone data
    promises = for fieldName, {idFieldName, pipelineName, include} of @_linkFields when include && id = linkedData[idFieldName]
      do (fieldName, idFieldName, pipelineName, include) =>
        Promise
        .then =>
          if id?
            if linkData = requestData?[fieldName] || postIncludeLinkedFieldData?[fieldName]
              merge {id}, linkData
            else if requestIncludeProp
              response.cachedPipelineGet pipelineName, id

        .catch (response) ->
          unless response.status == missing
            log.error "LinkFieldsFilter: error including #{fieldName}. #{idFieldName}: #{id}. pipelineName: #{pipelineName}. Error: #{response}", response.error
          # continue anyway
          null
        .then (value) ->
          linkedData[fieldName] = value if value?
    Promise.all promises
    .then -> linkedData

  @before
    create: (request) -> @_validate "preCreate", @preprocessRequest request
    update: (request) -> @_validate "preUpdate", @preprocessRequest request

  # to support 'include' for query results, just alter this to be an 'after-all-requests'
  # and have it detect is data is an array
  # Idealy, we'd also use the bulkGet feature
  @after
    all: (response) ->
      {data} = response
      response.withData if isPlainArray data
        # TODO: use bulkGet for efficiency
        Promise.all array data, (record) => @includeLinkedFields response, record

      else if isPlainObject data
        @includeLinkedFields response, data
      else
        @
