{log, Validator} = require 'art-foundation'
Handler = require '../handler'

module.exports = class ValidationHandler extends Handler
  constructor: (fields) ->
    @_validator = new Validator fields

  beforeCreate: (request) -> request.withData @_validator.preCreate request.data
  beforeUpdate: (request) -> request.withData @_validator.preUpdate request.data
