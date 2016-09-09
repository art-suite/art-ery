{log, Validator, defineModule, merge, isString, shallowClone, isPlainArray, Promise} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, ->
  class LinkFieldsFilter extends Filter
    constructor: (@_linkFields) ->
      super
      @_initValidator()

    _initValidator: ->
      @_normalizeLinkFields()
      for fieldName, {idFieldName, required} of @_linkFields

        @extendFields idFieldName,
          fieldType:  "trimmedString"
          required:   !!required

      @_validator = new Validator @fields

    # returns a new object
    normalizeDataBeforeWrite: (data) ->
      data = merge data
      for fieldName, {idFieldName} of @_linkFields
        data[idFieldName] = data[fieldName].id if data[fieldName]?.id
        delete data[fieldName]
      data

    _normalizeLinkFields: ->
      lf = {}
      for fieldName, {link, include, required} of @_linkFields
        lf[fieldName] =
          include: !!include
          required: !!required
          pipelineName: if isString link then link else fieldName
          idFieldName: fieldName + "Id"
      @_linkFields = lf

    # OUT: promise.then -> new data
    includeLinkedFields: (data) ->
      data = shallowClone data
      promises = for fieldName, {idFieldName, pipelineName, include} of @_linkFields when include && id = data[idFieldName]
        Promise
        .then           => id && @pipelines[pipelineName].get id
        .then (value)   -> data[fieldName] = if value? then value else null
        .catch (response) ->
          console.error response.error
          console.error "LinkFieldsFilter: error including #{fieldName}. #{idFieldName}: #{id}. pipelineName: #{pipelineName}. Error: #{response}", response.error
          # continue anyway
      Promise.all promises
      .then -> data

    @before
      create: (request) -> request.withData @_validator.preCreate @normalizeDataBeforeWrite request.data
      update: (request) -> request.withData @_validator.preUpdate @normalizeDataBeforeWrite request.data

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
