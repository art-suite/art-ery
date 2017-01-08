{
  BaseObject, CommunicationStatus, log, arrayWith
  defineModule, merge, isJsonType, isString, isPlainObject, inspect
  inspectedObjectLiteral
  toInspectedObjects
  formattedInspect
  Promise
} = require 'art-foundation'
ArtEry = require './namespace'
ArtEryBaseObject = require './ArtEryBaseObject'
{success, missing, failure, clientFailure} = CommunicationStatus

defineModule module, class RequestResponseBase extends ArtEryBaseObject

  constructor: (options) ->
    super
    {@filterLog} = options

  @property "filterLog"

  addFilterLog: (filter) -> @_filterLog = arrayWith @_filterLog, "#{filter}"

  @getter
    inspectedObjects: ->
      "#{@class.namespacePath}":
        toInspectedObjects @props

  subrequest: (pipelineName, type, requestOptions = {}) ->
    pipeline = ArtEry.pipelines[pipelineName]

    @rootRequest._subrequestCount++

    pipeline._processRequest new ArtEry.Request merge requestOptions, {
        type
        pipeline
        @session
        parentRequest: @
        @rootRequest
        originatedOnServer: true
      }
    .then (response) =>
      # log _processClientRequest: {response}
      {data, status} = response
      if response.isSuccessful
        if requestOptions.returnResponseObject then response else data
      else
        throw new ErrorWithInfo "subRequest #{pipelineName}.#{type} request #{status}", {response}

  rootRequestCachedGet: (pipelineName, key) ->
    ((@requestCache[pipelineName] ||= {}).get ||= {})[key] ||= @subrequest pipelineName, "get", {key}

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new @class merge @props, data: resolvedData

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withMergedData: (data) ->
    Promise.resolve(data).then (resolvedData) =>
      new @class merge @props, data: merge @data, resolvedData

  ###
  IN:
    null/undefined OR
    JSON-compabile data-type OR
    Response/Request OR
    something else - which is invalid, but is handled.

    OR a Promise returing one of the above

  OUT:
    if a Request or Response object was passed in, that is immediatly returned.
    Otherwise, this returns a Response object as follows:


    if data is null/undefined, return @missing
    if data is a JSON-compatible data structure, return @success with that data
    else, return @failure

  ###
  next: (data) ->
    Promise.resolve data
    .then (data) =>
      return data if data instanceof RequestResponseBase
      if !data?               then @missing()
      else if isJsonType data then @success {data}
      else
        log.error invalidXYZ: data
        throw new Error "invalid response data passed to RequestResponseBaseNext"
        # TODO: should return an inspected version of Data IFF the server is in debug-mode

  success:        (responseProps) -> @_toResponse success, responseProps
  missing:        (responseProps) -> @_toResponse missing, responseProps
  failure:        (responseProps) -> @_toResponse failure, responseProps
  clientFailure:  (responseProps) -> @_toResponse clientFailure, responseProps
  # NOTE: there is no serverFailure method because you should always use just 'failure'.
  # This is because you may be running on the client or the server. If running on the client, it isn't a serverFailure.
  # If status == "failure" in the server's response, the client will convert that status to serverFailure automatically.

  ###
  IN:
    status: legal CommunicationStatus
    responseProps: (optionally Promise returning:)
      PlainObject:          directly passed into the Response constructor
      String:               becomes data: message: string
      RequestResponseBase:  returned directly
      else:                 considered internal error, but it will create a valid, failing Response object
  OUT:
    promise.then (response) ->
    .catch -> # should never happen
  ###
  _toResponse: (status, responseProps) ->
    throw new Error "missing status" unless isString status

    Promise.resolve responseProps
    .then (responseProps = {}) =>
      switch
        when isPlainObject responseProps
          new ArtEry.Response merge @propsForResponse, responseProps, {status, @request}

        when responseProps instanceof RequestResponseBase
          responseProps

        when isString responseProps
          @_toResponse status, data: message: responseProps

        else
          @_toResponse failure, @_generateErrorResponseProps responseProps

  _toErrorResponseProps: (error) ->
    log @, {responseProps},
      data: message: if responseProps instanceof Error
          "Internal Error: ArtEry.RequestResponseBase#_toResponse received Error instance: #{formattedInspect responseProps}"
        else
          "Internal Error: ArtEry.RequestResponseBase#_toResponse received unsupported type"
