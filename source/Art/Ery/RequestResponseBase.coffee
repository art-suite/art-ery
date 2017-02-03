{
  BaseObject, CommunicationStatus, log, arrayWith
  defineModule, merge, isJsonType, isString, isPlainObject, inspect
  inspectedObjectLiteral
  toInspectedObjects
  formattedInspect
  Promise
  ErrorWithInfo
  object
  objectWithDefinedValues
} = require 'art-foundation'
ArtEry = require './namespace'
ArtEryBaseObject = require './ArtEryBaseObject'
{success, missing, failure, clientFailure} = CommunicationStatus
{config} = require './Config'

defineModule module, class RequestResponseBase extends ArtEryBaseObject

  constructor: (options) ->
    super
    {@filterLog} = options

  @property "filterLog"

  addFilterLog: (filter) -> @_filterLog = arrayWith @_filterLog, "#{filter}"

  @getter
    location: -> config.location
    requestType: -> @type
    pipelineName: -> @pipeline.getName()
    inspectedObjects: ->
      "#{@class.namespacePath}":
        toInspectedObjects objectWithDefinedValues @propsForClone

  ########################
  # ResponseProps
  ########################
  @getter
    responseProps: -> @response?.props || (@request._responseProps ||= {})

  @setter
    responseProps: -> throw new Error "cannot set responseProps"

  ########################
  # Subrequest
  ########################
  createSubRequest: (pipelineName, type, requestOptions) ->
    throw new Error "requestOptions must be an object" if requestOptions && !isPlainObject requestOptions
    pipeline = ArtEry.pipelines[pipelineName]
    throw new Error "Pipeline not registered: #{formattedInspect pipelineName}" unless pipeline

    new ArtEry.Request merge {originatedOnServer: true}, requestOptions, {
      type
      pipeline
      @session
      parentRequest: @request
      @rootRequest
    }

  subrequest: (pipelineName, type, requestOptions) ->
    subrequest = @createSubRequest pipelineName, type, requestOptions

    @rootRequest._subrequestCount++
    promise = subrequest.pipeline._processRequest subrequest
    .then (response) => response.toPromise requestOptions

    # update returns the same data a 'get' would - cache it in case we need it
    # USE CASE: I just noticed Oz doing this in triggers on message creation:
    #   updating post
    #   reading post to update postParticipant
    # This doesn't help if the 'get' fires before the 'update', but it does help
    # if we are lucky and it happens the other way.
    if type == "update" && !requestOptions?.props?.returnValues && isString subrequest.key
      @_getPipelineTypeCache(pipelineName, type)[subrequest.key] = promise

    promise

  _getPipelineTypeCache: (pipelineName, type) ->
    (@requestCache[pipelineName] ||= {})[type] ||= {}

  cachedSubrequest: (pipelineName, type, key) ->
    throw new Error "key must be a string (#{formattedInspect {key}})" unless isString key
    @_getPipelineTypeCache(pipelineName, type)[key] ||= @subrequest pipelineName, type, {key}

  cachedGet: cachedGet = (pipelineName, key) -> @cachedSubrequest pipelineName, "get", key
  cachedPipelineGet: cachedGet # depricated(?) alias

  # like cachedGet, excepts it success with null if it doesn't exist or if key doesn't exist
  cachedGetIfExists: (pipelineName, key) ->
    return Promise.resolve null unless key?
    @cachedGet pipelineName, key
    .catch (error) ->
      if error.info.response.status == missing
        Promise.resolve null
      else throw error


  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withData: (data) ->
    Promise.resolve(data).then (data) =>
      new @class merge @propsForClone, {data}

  # withKey: (newKey) ->
  #   Promise.resolve(newKey).then (key) =>
  #     new @class merge @propsForClone, {key}

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (newRequestWithNewData) ->
  ###
  withMergedData: (data) ->
    Promise.resolve(data).then (data) =>
      new @class merge @propsForClone, props: merge @_props, data: merge @data, data

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

  ##########################
  # PRIVATE
  ##########################
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
        when responseProps instanceof RequestResponseBase
          log.warn "_toResponse is instanceof RequestResponseBase - is this EVER used???"
          # if used, shouldn't this still transform Request objects into Response objects?
          responseProps

        when isPlainObject responseProps
          new ArtEry.Response merge @propsForResponse, responseProps, {status, @request}

        when isString responseProps
          @_toResponse status, data: message: responseProps

        # unsupported responseProps type is an internal failure
        else
          @_toResponse failure, @_generateErrorResponseProps responseProps

  _toErrorResponseProps: (error) ->
    log @, {responseProps},
      data: message: if responseProps instanceof Error
          "Internal Error: ArtEry.RequestResponseBase#_toResponse received Error instance: #{formattedInspect responseProps}"
        else
          "Internal Error: ArtEry.RequestResponseBase#_toResponse received unsupported type"
