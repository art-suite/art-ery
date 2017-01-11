{defineModule, log, Validator, merge, Promise} = require 'art-foundation'
Filter = require '../Filter'

defineModule module, class ValidationFilter extends Filter
  @location: "both"

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

