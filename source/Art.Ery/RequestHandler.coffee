{ErrorWithInfo, defineModule, Promise, isJsonType, log, neq} = require 'art-standard-lib'
RequestResponseBase = require './RequestResponseBase'

defineModule module, class RequestHandler extends require './ArtEryBaseObject'
  @abstractClass()

  ###
  OUT:
    promise.then (request or response) ->
      NOTE: response may be failing
    .catch -> internal errors only
  ###
  applyHandler: (request, handlerFunction, verboseFilterName) ->
    # pass-through if no filter
    return Promise.resolve request unless handlerFunction

    resultPromise = @_applyHandler request, handlerFunction

    if request.verbose
      resultPromise
      .tap (result) ->
        if result != request && neq request.summary, result.summary
          (if result.failed && !request.failed then log.error else log) "ArtEryApplyHandlerVerbose #{request.pipelineName}-#{request.type} #{verboseFilterName}":
            before: request.summary
            after:  result.summary
        else
          log "ArtEryApplyHandlerVerbose #{request.pipelineName}-#{request.type} #{verboseFilterName}": "no-change"
    else
      resultPromise

  _applyHandler: (request, handlerFunction) ->

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

    ###
    IN:
      request OR response

      if response, it is immediately returned
    OUT:
      promise.then -> response
        response may or maynot be successful, but it is always returned via the promise-success path

      promise.catch -> always means an internal failure

    OVERRIDE THIS
    ###
    # handleRequest: (request) ->
