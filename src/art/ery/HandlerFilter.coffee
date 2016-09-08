Foundation = require 'art-foundation'
Request = require './Request'
Response = require './Response'
Filter = require './Filter'

{BaseObject, Promise, log, isPlainObject, mergeInto, merge, shallowClone} = Foundation
{toResponse} = Response

module.exports = class HandlerFilter extends Filter

  process: (request, processNext) ->
    result = if handler = request.pipeline.handlers[request.type]
      handler.call request.pipeline, request
    else
      request

    toResponse result, request
