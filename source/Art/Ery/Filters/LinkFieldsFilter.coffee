{timeout, array, isPlainObject, formattedInspect, each, wordsArray, log, Validator, defineModule, merge, isString, shallowClone, isPlainArray, Promise} = require 'art-foundation'
Filter = require '../Filter'
{normalizeFieldProps} = Validator

defineModule module, class LinkFieldsFilter extends require './ValidationFilter'
  @location: "server"

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

    processedData = merge data
    Promise.all array @_linkFields,
      when: ({idFieldName}, fieldName) -> !data[idFieldName] && data[fieldName]
      with: ({idFieldName, autoCreate, pipelineName}, fieldName, __, linkedRecordData) =>
        Promise.then =>
          if linkedRecordData.id then linkedRecordData
          else if autoCreate     then request.subrequest pipelineName, "create", data: linkedRecordData
          else                   throw new Error "New record-data provided for #{fieldName}, but autoCreate is not enabled for this field. #{fieldName}: #{formattedInspect linkedRecordData}"
        .then (linkedRecordData) =>
          processedData[idFieldName] = linkedRecordData.id
          delete processedData[fieldName]
    .then -> request.withData processedData

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
  includeLinkedFields: (request, session, data) ->
    {include} = request.rootRequest.props
    return data unless include == "auto"

    linkedData = shallowClone data
    promises = for fieldName, {idFieldName, pipelineName, include} of @_linkFields when include && id = linkedData[idFieldName]
      do (fieldName, idFieldName, pipelineName, include) =>
        Promise
        .then           => id && request.cachedPipelineGet pipelineName, id
        .then (value)   -> linkedData[fieldName] = if value? then value else null
        .catch (response) ->
          log.error "LinkFieldsFilter: error including #{fieldName}. #{idFieldName}: #{id}. pipelineName: #{pipelineName}. Error: #{response}", response.error
          # continue anyway
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
      {request, session, data} = response
      switch request.type
        when "create", "update" then response
        else
          response.withData if isPlainArray data
            # TODO: use bulkGet for efficiency
            Promise.all(@includeLinkedFields request, session, record for record in data)
          else if isPlainObject data
            @includeLinkedFields request, session, data
          else
            data
