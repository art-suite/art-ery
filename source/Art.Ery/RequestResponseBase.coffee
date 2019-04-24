{
  timeout
  currentSecond
  log, arrayWith
  mergeWithoutNulls
  defineModule, merge, isJsonType, isString, isPlainObject, isArray
  inspect
  inspectedObjectLiteral
  toInspectedObjects
  formattedInspect
  Promise
  object
  isFunction
  objectWithDefinedValues
  objectWithout
  array
  isPromise
  compactFlatten
  objectKeyCount
  present
} = require 'art-standard-lib'
ArtEry = require './namespace'
ArtEryBaseObject = require './ArtEryBaseObject'
{networkFailure, failure, isClientFailure, success, missing, serverFailure, clientFailure, clientFailureNotAuthorized} = require 'art-communication-status'
{config} = require './Config'

###
TODO: merge reponse and request into one object

TODO: Work towards the concept of "oldData" - sometimes we need to know
 the oldData when updating. Specifically, ArtEryPusher needs to know the oldData
 to notify clients if a record is removed from one query and added to another.
 Without oldData, there is no way of knowing what old query it was removed from.
 In this case, either a) the client needs to send the oldData to the server of b)
 we need to fetch the oldData before overwriting it - OR we need to us returnValues: "allOld".

 Too bad there isn't a way to return BOTH the old and new fields with DynamoDb.

 Not sure if ArtEry needs any special code for "oldData." It'll probably be a convention
 that ArtEryAws and ArtEryPusher conform to. It's just a props from ArtEry's POV.
###

defineModule module, class RequestResponseBase extends ArtEryBaseObject

  constructor: (options) ->
    super
    @_creationTime = currentSecond()
    {@filterLog, @errorProps} = options

  @property "filterLog errorProps creationTime"

  addFilterLog: (filter) ->
    @_filterLog = arrayWith @_filterLog,
      name:
        if isString filter
          filter
        else
          filter.getLogName @type
      time: currentSecond()
    @

  @getter
    location:           -> @pipeline.location
    requestType:        -> @type
    pipelineName:       -> @pipeline.getName()
    requestDataWithKey: -> merge @requestData, @keyObject
    keyObject:          -> @request.pipeline.toKeyObject @key
    rootRequest:        -> @parentRequest?.rootRequest || @request
    originalRequest:    -> @_originalRequest ? @request.originalRequest
    startTime:          -> @rootRequest.creationTime
    endTime:            -> @creationTime
    wallTime:           -> @startTime - @endTime

    requestChain: ->

      compactFlatten [
        if @isResponse
          @request.requestChain
        else
          @parentRequest?.requestChain
        @
      ]

    simpleInspectedObjects: ->
      # TODO: instead of @propsForClone, let's just clone the stuff we want
      # Also, let's compact things a bit with: "pipelineName.requestType"
      # break out key and data from props... etc...

      props = objectWithout @props, "key", "data"
      props = null unless 0 < objectKeyCount props
      toInspectedObjects object {
        "#{@class.name}": @requestString
        @originatedOnServer
        @data
        @status
        props
        @errorProps
      }, when: (v) -> v?

    inspectedObjects: ->
      "Art.Ery.#{@class.name}": for request in @requestChain
        request.simpleInspectedObjects

  # Pass-throughs - to remove once we merge Request and Response
  @getter
    isSuccessful:       -> true
    isFailure:          -> @notSuccessful
    notSuccessful:      -> false

    requestSession:     -> @request.session
    requestProps:       -> @request.requestProps
    requestData:        -> @request.requestData

    isRootRequest:      -> @request.isRootRequest
    key:                -> @request.key || @responseData?.id
    pipeline:           -> @request.pipeline
    parentRequest:      -> @request.parentRequest
    isSubrequest:       -> !!@request.parentRequest
    type:               -> @request.type
    originatedOnServer: -> @request.originatedOnServer
    context:            -> @request.context
    pipelineAndType:    -> "#{@pipelineName}.#{@type}"

    requestString: ->
      if @key
        @pipelineAndType + " #{formattedInspect @key}"
      else
        @pipelineAndType

    description: -> @requestString

    requestPathArray: (into) ->
      localInto = into || []
      {parentRequest} = @
      if parentRequest
        parentRequest.getRequestPathArray localInto

      localInto.push @
      localInto

    requestPath: ->
      (r.requestString for r in @requestPathArray).join ' >> '

  toStringCore: ->
    "ArtEry.#{if @isResponse then 'Response' else 'Request'} #{@pipelineName}.#{@type}#{if @key then " key: #{@key}" else ''}"

  toString: ->
    "<#{@toStringCore()}>"

  ########################
  # Context Props
  ########################
  @getter
    requestCache:      -> @context.requestCache ||= {}
    subrequestCount:   -> @context.subrequestCount ||= 0

  @setter
    responseProps: -> throw new Error "cannot set responseProps"

  incrementSubrequestCount: -> @context.subrequestCount = (@context.subrequestCount | 0) + 1

  ########################
  # Subrequest
  ########################
  ###
  TODO:
    I think I may have a way clean up the subrequest API and do
    what is easy in Ruby: method-missing.

    Here's the new API:
      # request on the same pipeline
      request.pipeline.requestType requestOptions

      # request on another pipeline
      request.pipelines.otherPipelineName.requestType requestOptions

    Here's how:
      .pipeline and .pipelines are getters
      And the return proxy objects, generated and cached on the fly.

    Alt API idea:
      # same pipeline
      request.subrequest.requestType

      # other pipelines
      request.crossSubrequest.user.requestType

      I kinda like this more because it makes it clear we are talking
      sub-requests. This is just a ALIASes to the API above.
  ###
  createSubRequest: (pipelineName, type, requestOptions) ->
    throw new Error "requestOptions must be an object" if requestOptions && !isPlainObject requestOptions
    pipeline = ArtEry.pipelines[pipelineName]
    throw new Error "Pipeline not registered: #{formattedInspect pipelineName}" unless pipeline

    new ArtEry.Request merge {originatedOnServer: requestOptions?.originatedOnServer ? true}, requestOptions, {
      type
      pipeline
      verbose: @verbose
      session: requestOptions?.session || @session
      parentRequest: @request
      @context
    }

  subrequest: (pipelineName, type, requestOptions, b) ->
    requestOptions = merge b, key: requestOptions if isString requestOptions

    pipelineName = pipelineName.pipelineName || pipelineName
    subrequest = @createSubRequest pipelineName, type, requestOptions

    @incrementSubrequestCount()
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

  nonblockingSubrequest: (pipelineName, type, requestOptions) ->
    @subrequest pipelineName, type, requestOptions
    .then (result) =>
      if config.verbose
        log ArtEry: RequestResponseBase: nonblockingSubrequest: {
          status: "success"
          pipelineName
          type
          requestOptions
          parentRequest: {@pipelineName, @type, @key}
          result
        }

    .catch (error) =>
      log ArtEry: RequestResponseBase: nonblockingSubrequest: {
        status: "failure"
        pipelineName
        type
        requestOptions
        parentRequest: {@pipelineName, @type, @key}
        error
      }

    Promise.resolve()

  _getPipelineTypeCache: (pipelineName, type) ->
    (@requestCache[pipelineName] ||= {})[type] ||= {}

  cachedSubrequest: (pipelineName, requestType, keyOrRequestProps, d) ->
    throw new Error "DEPRICATED: 4-param cachedSubrequest" if d != undefined
    @_cachedSubrequest pipelineName, requestType, requestType, keyOrRequestProps

  _cachedSubrequest: (pipelineName, cacheType, requestType, keyOrRequestProps) ->
    key = if isString keyOrRequestProps
      keyOrRequestProps
    else
      keyOrRequestProps.key
    throw new Error "_cachedSubrequest: key must be a string (#{formattedInspect {key}})" unless isString key
    @_getPipelineTypeCache(pipelineName, cacheType)[key] ||=
      @subrequest pipelineName, requestType, keyOrRequestProps
      .catch (error) =>
        if error.status == networkFailure && requestType == "get"
          # attempt retry once
          timeout 20 + 10 * Math.random()
          .then => @subrequest pipelineName, requestType, keyOrRequestProps

        else throw error

  setGetCache: ->
    if @status == success && present(@key) && @responseData?
      @_getPipelineTypeCache(@pipelineName, "get")[@key] = Promise.then => @responseData

  cachedGet: cachedGet = (pipelineName, key) ->
    throw new Error "cachedGet: key must be a string (#{formattedInspect {key}})" unless isString key
    @cachedSubrequest pipelineName, "get", key

  # TODO: when we move LinkFieldsFilter's include-linking to the very-end of a client-initiated request
  #   this will become a simple alias for cacheGet, since all gets will be w/o include.
  cachedGetWithoutInclude: (pipelineName, key) ->
    throw new Error "cachedGetWithoutInclude: key must be a string (#{formattedInspect {key}})" unless isString key
    # use main get-cache if available
    @_getPipelineTypeCache(pipelineName, "get")[key] ||

    # if not, get w/o includes
    @_cachedSubrequest pipelineName,
      "get-no-include"
      "get"
      key:    key
      props:  include: false

  cachedPipelineGet: cachedGet # depricated(?) alias

  # like cachedGet, excepts it success with null if it doesn't exist or if key doesn't exist
  cachedGetIfExists: (pipelineName, key) ->
    return Promise.resolve null unless key?
    @cachedGet pipelineName, key
    .catch (error) ->
      if error.status == missing
        Promise.resolve null
      else throw error


  ##############################
  ##############################
  # Request Requirement Testing
  ##############################
  ##############################
  ### rejectIfErrors: success unless errors?
    IN:   errors: null, string or array of strings
    OUT:  Promise

      if errors?
        Promise.reject clientFailure with message based on errors
      else
        Promise.resolve request
  ###
  rejectIfErrors: (errors) ->
    if errors
      @clientFailure compactFlatten([@pipelineAndType, 'requirement not met', errors]).join ' - '
      .then (response) -> response.toPromise()
    else
      Promise.resolve @

  rejectNotAuthorizedIfErrors: (errors) ->
    if errors
      @clientFailureNotAuthorized compactFlatten([@pipelineAndType, 'requirement not met', errors]).join ' - '
      .then (response) -> response.toPromise()
    else
      Promise.resolve @

  @_resolveRequireTestValue: resolveRequireTestValue = (testValue) ->
    if isFunction testValue
      testValue = testValue()

    Promise.resolve testValue

  ### require: Success if !!test
    OUT: see @rejectIfErrors

    EXAMPLE: request.require myLegalInputTest, "myLegalInputTest"
  ###
  require: (test, context) ->
    resolveRequireTestValue test
    .then (test) =>
      @rejectIfErrors unless test then context ? []

  ### requiredFields
    Success if all props in fields exists (are not null or undefined)

    IN: fields (object)
    OUT-SUCCESS: fields

    OUT-REJECTED: see @rejectIfErrors

    EXAMPLE:
      # CaffeineScript's Object-Restructuring makes this particularly nice
      request.requiredFields
        {foo, bar} = request.data # creates a new object with just foo and bar fields

  ###
  requiredFields: (fields, context) ->
    missingFields = null
    for k, v of fields when !v?
      (missingFields ?= []).push k

    @rejectIfErrors if missingFields then ["missing fields: " + missingFields.join(", "), context]
    .then -> fields

  ### rejectIf: Success if !test
    OUT: see @rejectIfErrors

    EXAMPLE: request.rejectIf !myLegalInputTest, "myLegalInputTest"
  ###
  rejectIf: (testValue, context) ->
    resolveRequireTestValue testValue
    .then (testValue) => @require !testValue, context

  ############################################################
  ############################################################
  # Request originatedOnServer requirement testing
  ############################################################
  ############################################################

  ### requireServerOrigin: Success if @originatedOnServer
    OUT: see @rejectIfErrors

    EXAMPLE: request.requireServerOrigin "to use myServerOnlyFeature"
  ###
  requireServerOrigin: (context) -> @requireServerOriginOr false, context

  ### requireServerOriginOr: Success if testValue or @originatedOnServer
    OUT: see @rejectIfErrors

    EXAMPLE: request.requireServerOriginOr admin, "to use myAdminFeature"
  ###
  requireServerOriginOr: (testValue, context) ->
    return Promise.resolve @ if @originatedOnServer
    resolveRequireTestValue testValue
    .then (testValue) =>
      @rejectNotAuthorizedIfErrors unless testValue
        "originatedOnServer required " + if context?.match /\s*to\s/
          context
        else if context
          "to #{context}"
        else ''

  ### requireServerOriginIf: Success if !testValue or @originatedOnServer
    OUT: see @rejectIfErrors

    EXAMPLE: request.requireServerOriginIf clientAuthorized, "to use myFeature"
  ###
  requireServerOriginIf: (testValue, context) ->
    return Promise.resolve @ if @originatedOnServer
    resolveRequireTestValue testValue
    .then (testValue) =>
      @requireServerOriginOr !testValue, context

  ##################################
  # GENERATE NEW RESPONSES/REQUESTS
  ##################################

  # Clones this instance with optional overriding constructorOptions
  with: (constructorOptions) ->
    Promise.resolve(constructorOptions).then (constructorOptions) =>
      @_with constructorOptions

  # Private; expects 'o' to be a plainObject (not a promise -> plainObject)
  _with: (o) -> new @class merge @propsForClone, o

  ###
  IN: data can be a plainObject or a promise returning a plainObject
  OUT: promise.then (new request or response instance) ->

  withData:           new instance has @data replaced by `data`
  withMergedData:     new instance has @data merged with `data`
  withSession:        new instance has @session replaced by `session`
  withMergedSession:  new instance has @session merged with `session`
  ###
  withData:                     (data)  -> Promise.resolve(data).then   (data)  => @_with {data}
  withMergedData:               (data)  -> Promise.resolve(data).then   (data)  => @_with data: merge @data, data

  withProps:                    (props) -> Promise.resolve(props).then  (props) => @_with {props, key: props.key, data: props.data}
  withMergedProps:              (props) -> Promise.resolve(props).then  (props) => @_with key: props.key, data: props.data, props: merge @props, props
  withMergedPropsWithoutNulls:  (props) -> Promise.resolve(props).then  (props) => @_with key: props.key, data: props.data, props: mergeWithoutNulls @props, props

  withMergedErrorProps:         (errorProps) -> Promise.resolve(errorProps).then (errorProps) => @_with errorProps: merge @errorProps, errorProps

  withSession:                  (session) -> Promise.resolve(session).then  (session) => @_with {session}
  withMergedSession:            (session) -> Promise.resolve(session).then  (session) => @_with session: merge @session, session

  respondWithSession:           (session) -> @success {session}
  respondWithMergedSession:     (session) -> @success session: merge @session, session

  ###
  IN:
    withFunction, whenFunction
    OR: object:
      with: withFunction
      when: whenFunction

  withFunction: (record, requestOrResponse) ->
    IN:
      record: a plain object
      requestOrResponse: this
    OUT: See EFFECT below
      (can return a Promise in all situations)

  whenFunction: (record, requestOrResponse) -> t/f
    withFunction is only applied if whenFunction returns true

  EFFECT:
    if isPlainObject @data
      called once: singleRecordTransform @data
      if singleRecordTransform returns:
        null:         >> return status: missing
        plainObject:  >> return @withData data
        response:     >> return response

      See singleRecordTransform.OUT above for results

    if isArray @data
      Basically:
        @withData array record in @data with singleRecordTransform record

      But, each value returned from singleRecordTransform:
        null:                              omitted from array results
        response.status is clientFailure*: omitted from array results
        plainObject:                       returned in array results
        if any error:
            exception thrown
            rejected promise
            response.status is not success and not clientFailure
          then a failing response is returned

  TODO:
    Refactor. 'when' should really be a Filter - just like Caffeine/CoffeeScript comprehensions.
      Right now, if when is false, the record is still returned, just not "withed"
      Instead, only records that pass "when" should even be returned.
  ###
  defaultWhenTest = (data, request) -> request.pipeline.isRecord data
  withTransformedRecords: (withFunction, whenFunction = defaultWhenTest) ->
    if isPlainObject options = withFunction
      withFunction = options.with
      whenFunction = options.when || defaultWhenTest

    if isPlainObject @data
      Promise.resolve if whenFunction @data, @
        @next withFunction @data, @
      else
        @
    else if isArray @data
      firstFailure = null
      transformedRecords = array @data, (record) =>
        Promise.then =>
          if whenFunction record, @ then withFunction record, @
          else record
        .catch (error) =>
          if error.status == "missing" then null
          else if response = error?.props?.response
            response
          else
            throw error
        .then (out) ->
          if out?.status && out instanceof RequestResponseBase
            if isClientFailure out.status
              out._clearErrorStack?()
              null
            else
              firstFailure ||= out
          else
            out

      Promise.all transformedRecords
      .then (records) =>
        firstFailure || @withData compactFlatten records

    else Promise.resolve @

  ###
  next is used right after a filter or a handler.
  It's job is to convert the results into a request or response object.

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

    # send response-errors back through the 'resolved' promise path
    # We allow them to be thrown in order to skip parts of code, but they should be returned normally
    , (error) =>
      if error.props?.response?.isResponse
        error.props.response
      else
        @failure {error}

  success:                    (responseProps) -> @toResponse success,                     responseProps
  missing:                    (responseProps) -> @toResponse missing,                     responseProps
  clientFailure:              (responseProps) -> @toResponse clientFailure,               responseProps
  clientFailureNotAuthorized: (responseProps) -> @toResponse clientFailureNotAuthorized,  responseProps
  failure:                    (responseProps) -> @toResponse failure,                     responseProps
  # NOTE: there is no serverFailure method because you should always use just 'failure'.
  # This is because you may be running on the client or the server. If running on the client, it isn't a serverFailure.
  # If status == "failure", the ArtEry HTTP server will convert that status to serverFailure automatically.

  rejectWithMissing:                    (responseProps) -> @toResponse missing,                     responseProps, true
  rejectWithClientFailure:              (responseProps) -> @toResponse clientFailure,               responseProps, true
  rejectWithClientFailureNotAuthorized: (responseProps) -> @toResponse clientFailureNotAuthorized,  responseProps, true
  rejectWithFailure:                    (responseProps) -> @toResponse failure,                     responseProps, true

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
  toResponse: (status, responseProps, returnRejectedPromiseOnFailure = false) ->
    throw new Error "missing status" unless isString status

    # status = responseProps.status if isString responseProps?.status

    # if status != success && config.verbose
    #   log.error RequestResponseBase_toResponse:
    #     arguments: {status, responseProps}
    #     config: verbose: true
    #     request: {
    #       @requestPath
    #       @requestProps
    #       @session
    #     }
    #     error: Promise.reject new Error

    Promise.resolve responseProps
    .then (responseProps = {}) =>
      switch
        when responseProps instanceof RequestResponseBase
          log.warn "toResponse is instanceof RequestResponseBase - is this EVER used???"
          # if used, shouldn't this still transform Request objects into Response objects?
          responseProps

        when isPlainObject responseProps
          new ArtEry.Response merge @propsForResponse, responseProps, {status, @request}

        when isString responseProps
          @toResponse status, data: message: responseProps

        # unsupported responseProps type is an internal failure
        else
          @toResponse failure, @_toErrorResponseProps responseProps
    .then (response) ->
      if returnRejectedPromiseOnFailure
        response.toPromise()
      else
        response


  _toErrorResponseProps: (error) ->
    log @, {responseProps},
      data: message: if responseProps instanceof Error
          "Internal Error: ArtEry.RequestResponseBase#toResponse received Error instance: #{formattedInspect responseProps}"
        else
          "Internal Error: ArtEry.RequestResponseBase#toResponse received unsupported type"
