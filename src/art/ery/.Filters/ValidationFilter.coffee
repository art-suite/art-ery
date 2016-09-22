{defineModule, log, Validator} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class ValidationFilter extends Filter
  @filterLocation: "both"

  constructor: (@_fields) ->
    super
    @_validator = new Validator @_fields

  @before
    create: (request) -> request.withData @_validator.preCreate request.data, context: "ValidationFilter(pipelineName: '#{request.pipeline.getName()}')"
    update: (request) -> request.withData @_validator.preUpdate request.data, context: "ValidationFilter(pipelineName: '#{request.pipeline.getName()}')"
