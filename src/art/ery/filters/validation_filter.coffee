{log, Validator} = require 'art-foundation'
Filter = require '../filter'

module.exports = class ValidationFilter extends Filter
  constructor: (fields) ->
    @_validator = new Validator fields

  @before
    create: (request) -> request.withData @_validator.preCreate request.data
    update: (request) -> request.withData @_validator.preUpdate request.data
