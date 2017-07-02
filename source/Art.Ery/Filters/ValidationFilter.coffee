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
    @_validator = new Validator @fields

  @before
    create: (request) -> @_validate "preCreate", request
    update: (request) -> @_validate "preUpdate", request

  _validate: (method, request) ->
    Promise.resolve request
    .then (request) =>
      @_validator[method] request.data, context: "#{request.pipeline?.getName() || "no pipeline?"} #{@class.getName()}"
      .then (data) -> request.withData data
      .catch ({message, info}) -> request.clientFailure data: merge {message}, info

