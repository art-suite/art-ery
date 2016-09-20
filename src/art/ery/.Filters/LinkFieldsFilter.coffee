{isPlainObject, newMapFromEach, wordsArray, log, Validator, defineModule, merge, isString, shallowClone, isPlainArray, Promise} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, ->
  class LinkFieldsFilter extends Filter
    constructor: (@_linkFields) ->
      super
      @_initValidator()

    _initValidator: ->
      @_linkFields = LinkFieldsFilter.normalizeLinkFields @_linkFields
      for fieldName, {idFieldName, required} of @_linkFields

        @extendFields idFieldName,
          fieldType:  "trimmedString"
          required:   !!required

      @_validator = new Validator @fields

    # returns a new object
    preprocessData: (data) ->
      log LinkFieldsFilter: preprocessData:
        pipeline: @getName()
        linkFields: @_linkFields
      data = merge data
      promises = for fieldName, {idFieldName, autoCreate, pipelineName} of @_linkFields
        Promise.then =>
          linkedRecordData = data[fieldName]
          log autoCreate: fieldName if autoCreate
          if autoCreate && linkedRecordData && !data[idFieldName] && !linkedRecordData.id
            @pipelines[pipelineName].create data: linkedRecordData
          else linkedRecordData
        .then (linkedRecordData) =>
          data[idFieldName] = linkedRecordData.id if linkedRecordData?.id
          delete data[fieldName]
      Promise.all promises
      .then -> data

    booleanProps = wordsArray "link required include autoCreate"
    @normalizeLinkFields: (linkFields) ->
      newMapFromEach linkFields, (lf, fieldName, fieldProps) ->
        for prop in booleanProps when isPlainObject val = fieldProps[prop]
          fieldProps = merge val, fieldProps
          fieldProps[prop] = true

        {link, include, required, autoCreate} = fieldProps
        lf[fieldName] =
          autoCreate: !!autoCreate
          include: !!include
          required: !!required
          pipelineName: if isString link then link else fieldName
          idFieldName: fieldName + "Id"

    # OUT: promise.then -> new data
    includeLinkedFields: (data) ->
      linkedData = shallowClone data
      promises = for fieldName, {idFieldName, pipelineName, include} of @_linkFields when include && id = linkedData[idFieldName]
        Promise
        .then           => id && @pipelines[pipelineName].get key: id
        .then (value)   -> linkedData[fieldName] = if value? then value else null
        .catch (response) ->
          log.error "LinkFieldsFilter: error including #{fieldName}. #{idFieldName}: #{id}. pipelineName: #{pipelineName}. Error: #{response}", response.error
          # continue anyway
      Promise.all promises
      .then -> linkedData

    @before
      create: (request) -> request.withData @_validator.preCreate @preprocessData(request.data), context: "LinkFieldsFilter for #{request.pipeline.getName()} fields"
      update: (request) -> request.withData @_validator.preUpdate @preprocessData(request.data), context: "LinkFieldsFilter for #{request.pipeline.getName()} fields"

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
            else
              @includeLinkedFields response.data
