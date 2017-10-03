{defineModule, Promise} = require 'art-standard-lib'
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

    Promise.then =>
      if handlerFunction
        request.addFilterLog @
        handlerFunction.call @, request
      else
        # pass-through if no filter
        request

    .then (data) =>
      return data if data instanceof RequestResponseBase
      if !data?               then request.missing()
      else if isJsonType data then request.success {data}
      else
        log.error invalidXYZ: data
        throw new Error "invalid response data passed to RequestResponseBaseNext"
        # TODO: should return an inspected version of Data IFF the server is in debug-mode

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
