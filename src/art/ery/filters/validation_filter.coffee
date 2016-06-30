{log, Validator} = require 'art-foundation'
Filter = require '../filter'

module.exports = class ValidationFilter extends Filter
  constructor: (fields) ->
    @_validator = new Validator fields

  beforeCreate: (request) -> request.withData @_validator.preCreate request.data
  beforeUpdate: (request) -> request.withData @_validator.preUpdate request.data
