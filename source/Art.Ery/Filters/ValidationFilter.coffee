{defineModule, log, Validator, merge, Promise} = require 'art-foundation'
Filter = require '../Filter'

###
TODO!!!
# BUG: ValidationFilter doesn't validated the TimestampFilter's fields! (when using createDatabaseFilters)
# PROBLEM: ValidationFilter only validates the fields it is passed.
# SOLUTION: we need it to always validate all fields declared for the pipeline.
# createDatabaseFilters needs to change order: it needs to run ValidationFilter last.

I almost want to rename this "FieldTypesFilter" - since it both validates and preprocesses.
It should actually also have an @after pass that at least converts timestamps back into Dates.
###

defineModule module, class ValidationFilter extends Filter
  @location "both"

  constructor: (options) ->
    super
    # NOTE - not using Validator's 'exclusive' feature because we need to test
    #   unexpected fields against pipeline.fields not the options.fields that were passed in.
    @_exclusive = options?.exclusive
    @_validator = new Validator @fields

  @before
    create: (request) -> @_validate "validateCreate", request
    update: (request) -> @_validate "validateUpdate", request

  _validate: (method, request) ->
    Promise.then =>
      validatedData = @_validator[method] request.data, context: "#{request.pipeline?.getName() || "no pipeline?"} #{@class.getName()}"
      data = validatedData if request.location != "client"

      rejection = if @_exclusive
        {fields} = request.pipeline
        unexpectedFields = null
        for k, v of data when !fields[k]
          (unexpectedFields ||= []).push k

        if unexpectedFields
          Promise.reject
            message: "unexpected fields: #{unexpectedFields.join ', '}"
            info: unexpected: unexpectedFields

      rejection || request.withData data

    .catch ({message, info}) ->
      log {request}
      request.clientFailure data: merge {message}, info

