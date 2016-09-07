{log, Validator, defineModule, merge} = require 'art-foundation'
Filter = require '../Filter'
{getNamedPipeline} = require '../Pipeline'

defineModule module, ->
  class LinkFieldsFilter extends Filter
    constructor: (@_linkFields) ->
      super
      @_initValidator()

    _initValidator: ->
      @_fields = {}
      for fieldName, props of @_linkFields

        @_fields[props.idFieldName = fieldName + "Id"] =
          fieldType: "trimmedString"
          required: !!props.required

      @_validator = new Validator @_fields

    # returns a new object
    normalizeDataBeforeWrite: (data) ->
      data = merge data
      for fieldName, {idFieldName} of @_linkFields
        data[idFieldName] = data[fieldName].id if data[fieldName]?.id
        delete data[fieldName]
      data

    # OUT: promise.then -> new data
    normalizeDataAfterRead: (data) ->
      data = merge data
      promises = for fieldName, {idFieldName, linkTo, include} of @_linkFields when include && id = data[idFieldName]
        Promise.resolve()
        .then => id && getNamedPipeline(linkTo || fieldName).get id
        .then (value) -> data[fieldName] = if value? then value else null
        .catch (error) ->
          console.error "LinkFieldsFilter: error including #{fieldName}. #{idFieldName}: #{id}. linkTo: #{linkTo}. Error: #{error}", error
          # continue anyway
      Promise.all promises
      .then -> data

    @before
      create: (request) -> request.withData @_validator.preCreate @normalizeDataBeforeWrite request.data
      update: (request) -> request.withData @_validator.preUpdate @normalizeDataBeforeWrite request.data

    @after
      get: (response) -> response.withData @normalizeDataAfterRead response.data
