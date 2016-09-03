{log, Validator} = require 'art-foundation'
Filter = require '../Filter'

module.exports = class ValidationFilter extends Filter
  constructor: (@_fields) ->
    super
    @_validator = new Validator @_fields

  @before
    create: (request) -> request.withData @_validator.preCreate request.data
    update: (request) -> request.withData @_validator.preUpdate request.data
