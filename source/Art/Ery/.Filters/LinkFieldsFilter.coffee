{array, isPlainObject, each, wordsArray, log, Validator, defineModule, merge, isString, shallowClone, isPlainArray, Promise} = require 'art-foundation'
Filter = require '../Filter'
{normalizeFieldProps} = Validator

defineModule module, class LinkFieldsFilter extends Filter
  @location: "server"

  constructor: (@_linkFields) ->
    super
    @_initValidator()

  _initValidator: ->
    @_linkFields = LinkFieldsFilter.normalizeLinkFields @_linkFields
    for fieldName, fieldProps of @_linkFields
      props = merge fieldProps, fieldType:  "trimmedString"
      delete props.idFieldName
      @extendFields fieldProps.idFieldName, normalizeFieldProps props

    @_validator = new Validator @fields

  # returns a new object
  preprocessData: ({type,pipeline, data}) ->
    processedData = merge data
    Promise.all array @_linkFields, ({idFieldName, autoCreate, pipelineName}, fieldName) =>
        linkedRecordData = data[fieldName]
        linkedRecordId = data[idFieldName]
        if linkedRecordData
          Promise.then =>
            if linkedRecordData.id
              throw new Error "Two different ids for #{fieldName} provided: #{fieldName}.id: #{linkedRecordData.id} != #{idFieldName}: #{linkedRecordId}" if linkedRecordId? && linkedRecordId != linkedRecordData.id
              linkedRecordData
            else if autoCreate
              @pipelines[pipelineName].create data: linkedRecordData
            else throw new Error "New record-data provided for #{fieldName}, but autoCreate is not enabled for this field."
          .then (linkedRecordData) =>
            processedData[idFieldName] = linkedRecordData.id
            delete processedData[fieldName]
    .then -> processedData

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
  includeLinkedFields: (data) ->
    linkedData = shallowClone data
    promises = for fieldName, {idFieldName, pipelineName, include} of @_linkFields when include && id = linkedData[idFieldName]
      do (fieldName, idFieldName, pipelineName, include) =>
        Promise
        .then           => id && @pipelines[pipelineName].get key: id
        .then (value)   -> linkedData[fieldName] = if value? then value else null
        .catch (response) ->
          log.error "LinkFieldsFilter: error including #{fieldName}. #{idFieldName}: #{id}. pipelineName: #{pipelineName}. Error: #{response}", response.error
          # continue anyway
    Promise.all promises
    .then -> linkedData

  @before
    create: (request) -> request.withData @_validator.preCreate @preprocessData(request), context: "LinkFieldsFilter for #{request.pipeline.getName()} fields"
    update: (request) -> request.withData @_validator.preUpdate @preprocessData(request), context: "LinkFieldsFilter for #{request.pipeline.getName()} fields"

  # to support 'include' for query results, just alter this to be an 'after-all-requests'
  # and have it detect is data is an array
  # Idealy, we'd also use the bulkGet feature
  @after
    all: (response) ->
      switch response.request.type
        when "create", "update" then response
        else
          {data} = response
          response.withData if isPlainArray data
            # TODO: use bulkGet for efficiency
            Promise.all(@includeLinkedFields record for record in data)
          else if isPlainObject data
            @includeLinkedFields response.data
          else
            data
