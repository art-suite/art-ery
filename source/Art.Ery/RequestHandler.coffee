{ErrorWithInfo, defineModule, Promise, isJsonType, log} = require 'art-standard-lib'
RequestResponseBase = require './RequestResponseBase'

defineModule module, class RequestHandler extends require './ArtEryBaseObject'
  @abstractClass()

  ###
  OUT:
    promise.then (request or response) ->
      NOTE: response may be failing
    .catch -> internal errors only
  ###
  applyHandler: (request, handlerFunction) ->
    # pass-through if no filter
    return Promise.resolve request unless handlerFunction

    Promise.then =>
      request.addFilterLog @
      handlerFunction.call @, request

    .then (data) =>
      unless data?                                then request.missing()
      else if data instanceof RequestResponseBase then data
      else if isJsonType data                     then request.success {data}
      else
        throw new ErrorWithInfo "invalid response data passed to RequestResponseBaseNext", {data}

    # send response-errors back through the 'resolved' promise path
    # We allow them to be thrown in order to skip parts of code, but they should be returned normally
    , (error) =>
      if error.props?.response?.isResponse
        error.props.response
      else
        request.failure errorProps:
          exception: error
          source:
            this: @
            function: handlerFunction
