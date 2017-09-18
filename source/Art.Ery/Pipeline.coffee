Foundation = require 'art-foundation'
Response = require './Response'
Request = require './Request'
Filter = require './Filter'
Session = require './Session'
{config} = require './Config'
Filters = require './Filters'
PipelineQuery = require './PipelineQuery'

PipelineRegistry = require './PipelineRegistry'

{
  each
  object
  compactFlatten
  BaseObject, reverseForEach, Promise, log, isPlainObject, inspect, isString, isClass, isFunction, inspect
  CommunicationStatus
  merge
  isPlainArray
  decapitalize
  defineModule
  Validator
  mergeInto
  arrayToTruthMap
  lowerCamelCase
  peek
  inspectedObjectLiteral
  escapeRegExp
  formattedInspect
  pushIfNotPresent
  w
} = Foundation
{normalizeFieldProps} = Validator

{success, missing} = CommunicationStatus

###
TODO:
  Factor out all flux-related stuff into:
  class FluxReadyPipeline extends Pipeline

  DONT put it in Flux/
    WHY? Server-side, we won't include Flux/
###
defineModule module, class Pipeline extends require './ArtEryBaseObject'

  @register: ->
    @singletonClass()
    PipelineRegistry.register @

  # copy-paste this line to any sub-class that shouldn't auto-register
  @abstractClass()

  @postCreateConcreteClass: ({hotReloaded}) ->
    @register() unless hotReloaded
    @_defineQueryHandlers()
    @_defineClientHandlerMethods()
    @_initFields()
    Neptune.Art.Ery.Flux?.ArtEryFluxModel.createModel @getSingleton()
    super

  @instantiateFilter: instantiateFilter = (filter) ->
    if isClass filter                 then new filter
    else if isFunction filter         then filter @
    else if filter instanceof Filter  then filter
    else if isPlainObject filter      then new Filter filter
    else throw "invalid filter: #{inspect filter} #{filter instanceof Filter}"

  @getAliases: -> @_aliases || {}

  @addDatabaseFilters: (options) ->
    @filter Filters.createDatabaseFilters options, @

  toKeyString: (key) ->
    return key unless key?
    if isString key
      key
    else if @dataToKeyString && isPlainObject key
      @dataToKeyString key
    else
      throw new Error "override toKeyString or dataToKeyString for non-string-keys like: #{formattedInspect key}"

  # override if desired
  # used by Request/Response.withTransformedRecords
  isRecord: (data) -> data?.id

  ###########################
  # Declarative API
  ###########################

  @extendableProperty
    queries: {}
    filters: []
    handlers: {}
    clientApiMethodList: []
    fields: {}
    fluxModelMixins: []
    publicRequestTypes: {}

  @publicRequestTypes: (v) ->
    @extendPublicRequestTypes object (w v), -> true

  ###
  @fluxModelMixin adds a mixin to fluxModelMixins

  When createing FluxModels for this pipeline (via ArtEryFluxModel.createModel for example),
  both the records model and each query-model will get these mixins.

  Example:
    class MyPipeline extends Pipeline
      @fluxModelMixin FluxModelMixinA
      @fluxModelMixin FluxModelMixinB

    # this action
    ArtEryFluxModel.defineModelsForAllPipelines()

    # defines this model:
    class MyPipeline extends FluxModelMixinB FluxModelMixinA ArtEryFluxModel
  ###
  @fluxModelMixin: (mixin) -> @extendFluxModelMixins mixin


  ###
  define a single filter OR an array of filters to define.

  NOTE: the order of filter definitions matter:
    last-defined filters FIRST in the before-filter sequence
    last-defined filters LAST in the after-filter sequence

    Example request processing sequence:

      filterDefinedLast.beforeFilter
        filterDefinedSecond.beforeFilter
          filterDefinedFirst.beforeFilter
            handler
          filterDefinedFirst.afterFilter
        filterDefinedSecond.afterFilter
      filterDefinedLast.afterFilter

  IN:
    name: "myFilter"                    # only used for debug purposes
    location: "server"/"client"/"both"  # where the filter will be applied
    before: map:
      requestType: (request) ->
        OUT one of these (or a promise returning one of these):
          request
          - the same request if nothing was filtered
          - a new request with the new, filtered values

          response in the form of:
          - new Response
          - null        >> request.missing()
          - string      >> request.success data: message: string
          - plainObject >> request.success data: plainObject
          - plainArray  >> request.success data: plainArray
          NOTE, if a response is returned, it shortcircuits the handler and all other
            filters. The response is returned directly to the caller.

    after: map:
      requestType: (response) ->
        OUT: same or new response
           NOTE: all after-filters are applied if the handler generated the first response object
           UNLESS there is an error, in which case the error is returned directly.
  ###
  @filter:        (filter)         -> @extendFilters preprocessFilter filter

  ###
  add one or more handlers

  IN map:
    requestType: (request) ->
      IN: ArtEry.Request instance
      OUT:
        ArtEry.Response instance
      OR
        plain data which will be wrapped up in an ArtEry.Response instance

  @handler and @handlers are aliases.
  ###
  @handler:  @extendHandlers
  @handlers: @extendHandlers

  @remoteServer:    (@_remoteServer)    -> # override default (see config.remoteServer)
  @apiRoot:         (@_apiRoot)         -> # override default (see config.apiRoot)
  @tableNamePrefix: (@_tableNamePrefix) -> # override default (see config.tableNamePrefix)

  ###
  declare a query - used by ArtEryFlux

  IN: map:
    queryName: map:
      class properties for anonymous subclass of ArtEryQueryFluxModel

  queryName is used as both the ArtFlux model-name AND the ArtEry request-type:
    Example:
      # invoke query
      myPipeline.myQueryName key: queryKey

      # subscribe to Model in FluxComponent
      @subscriptions
        myQueryName: queryKey
  ###
  @query: (map) ->
    @extendQueries object map, (options, queryName) -> new PipelineQuery queryName, options

  ###
  aliases

  INPUT: zero or more strings or arrays of strings
    - arbitrary nesting of arrays is OK
    - nulls are OK, they are ignored
  OUTPUT: null

  NOTE: @aliases can only be called once

  example:
    class Post extends Pipeline
      @aliases "chapterPost"

  purpose:
    - used by ArtEryFluxComponent to make model aliases
      (see FluxModel.aliases)
  ###
  @aliases: ->
    @_aliases = each arguments, map = {}, (v, k) ->
      map[lowerCamelCase v] = true
    @

  ######################
  # constructor
  ######################
  constructor: (@_options = {}) ->
    super

  getPrefixedTableName: (tableName) => "#{@tableNamePrefix}#{tableName}"

  @classGetter
    pipelineName: -> @_pipelineName || decapitalize @getName()

  @getter "options",
    pipelineName: -> @class.getPipelineName()
    tableNamePrefix: -> @class._tableNamePrefix || config.tableNamePrefix
    tableName: -> @getPrefixedTableName @name
    normalizedFields: ->
      nf = {}
      for k, v of @fields
        nf[k] = normalizeFieldProps v
      nf

    name:     -> @_name     ||= @_options.name    || decapitalize @class.getName()
    session:  -> @_session  ||= @_options.session || Session.singleton
    handlerRequestTypesMap: (into = {}) ->
      mergeInto into, @handlers
      into

    filterRequestTypesMap: (into = {}) ->
      for filter in @filters
        mergeInto into, filter.beforeFilters
      into

    requestTypesMap: (into = {})->
      @getHandlerRequestTypesMap @getFilterRequestTypesMap into

    requestTypes: -> Object.keys @requestTypesMap

    aliases: -> Object.keys @class.getAliases()
    inspectedObjects: -> inspectedObjectLiteral @name
    isRemoteClient: -> !!@remoteServer
    apiRoot: -> @class._apiRoot || config._apiRoot

    remoteServer: -> @class._remoteServer || config.remoteServer

    location: ->
      if @remoteServer && config.location != "server"
        "client"
      else
        config.location

    restPath: -> @_restPath ||= "/#{config.apiRoot}/#{@name}"
    restPathRegex: -> @_restPathRegex ||= ///
      ^
      #{escapeRegExp @restPath}
      (?:-([a-z0-9_]+))?          # optional request-type (if missing, it is derived from the HTTP method)
      (?:\/([^?]+))?       # optional key
      (?=\?|$)
      ///i

    groupedFilters: ->
      @_groupedFilters ||= Pipeline.groupFilters @filters

    beforeFilters: -> @_beforeFilters ||= @groupedFilters.slice().reverse()
    afterFilters: -> @groupedFilters
    status: -> "OK"

  # use a stable sort
  @groupFilters: (filters) ->
    groupLevels = []
    for {group} in filters
      pushIfNotPresent groupLevels, group

    sortedFilters = []
    for groupLevel in groupLevels.sort()
      for filter in filters when groupLevel == filter.group
        sortedFilters.push filter
    sortedFilters

  getBeforeFilters: (request) -> filter for filter in @beforeFilters when filter.getBeforeFilter request
  getAfterFilters:  (request) -> filter for filter in @afterFilters  when filter.getAfterFilter request

  createRequest: (type, options) ->
    options = key: options if isString options
    Promise
    .resolve options.session || @session.loadedDataPromise
    .then (sessionData) =>
      new Request merge options,
        type:     type
        pipeline: @
        session:  sessionData

  ###############################
  # Development Reports
  ###############################
  getRequestProcessingReport: (location = @location) ->
    object @requestTypes, (requestType) =>
      compactFlatten([
        inspectedObjectLiteral(filter.getName()) for filter in @getBeforeFilters {requestType, location}
        inspectedObjectLiteral if location == "client" then "[remote request]" else "[local handler]"
        inspectedObjectLiteral(filter.getName()) for filter in @getAfterFilters {requestType, location}
      ]) #.join ' > '

  @getter
    pipelineReport: (processingLocation)->
      out =
        tableName: @tableName
        fields: object @fields, (fieldProps) ->
          each Object.keys(fieldProps).sort(), out = {}, (k) ->
            v = fieldProps[k]
            unless isFunction v
              out[k] = v

      if processingLocation
        out["#{processingLocation}Processing"] = @getRequestProcessingReport "client"
      else
        out.clientSideRequestProcessing = @getRequestProcessingReport "client"
        out.serverSideRequestProcessing = @getRequestProcessingReport "server"
        out.serverlessDevelopmentRequestProcessing = @getRequestProcessingReport "both"

      out

    apiReport: (options = {}) ->
      {server, publicOnly} = options
      object @requestTypes,
        when: publicOnly && (type) => @getPublicRequestTypes()[type]
        with: (type) =>
          {method, url} = Request.getRestClientParamsForArtEryRequest
            server: @remoteServer || server
            type: type
            restPath: @restPath
          "#{method.toLocaleUpperCase()}": url

  ###################
  # PRIVATE
  ###################

  preprocessFilter = (filter) ->
    if isPlainArray filter
      instantiateFilter f for f in filter when f
    else
      instantiateFilter filter

  ###
  query handler-functions: (request) -> response or any other value allowed for handlers
  ###
  @_defineQueryHandlers: ->
    for k, pipelineQuery of @getQueries()
      throw new Error "pipelineQuery not a PipelineQuery" unless pipelineQuery instanceof PipelineQuery
      throw new Error "pipelineQuery has no query" unless isFunction pipelineQuery.query
      @extendHandlers k, pipelineQuery.query

  ###
  OUT:
    promise.then -> request OR response
      requests are always 'successful-so-far'
      responses may or maynot be successful, but they are always returned via the promise-success path

    promise.catch -> always means an internal failure
  ###
  _applyBeforeFilters: (request) ->
    filters = @getBeforeFilters request
    filterIndex = 0

    applyNextFilter = (partiallyBeforeFilteredRequest) =>
      if partiallyBeforeFilteredRequest.isResponse || filterIndex >= filters.length
        Promise.resolve partiallyBeforeFilteredRequest
      else
        (filter = filters[filterIndex++]).processBefore partiallyBeforeFilteredRequest
        .then (result) =>
          result.handled beforeFilter: filter.getName() if result.isResponse && result.isSuccessful
          applyNextFilter result

    applyNextFilter request

  ###
  IN:
    request OR response

    if response, it is immediately returned
  OUT:
    promise.then -> response
      response may or maynot be successful, but it is always returned via the promise-success path

    promise.catch -> always means an internal failure
  ###
  _applyHandler: (requestOrResponse) ->
    Promise.try =>
      if requestOrResponse.isResponse
        return requestOrResponse
      else
        request = requestOrResponse

      if @location == "client" && @remoteServer
        request.sendRemoteRequest @remoteServer

      else if handler = @handlers[request.type]
        request.next handler.call @, request
        .then (response) => response.handled handler: requestOrResponse.type

      else
        message = "no Handler for request type: #{request.type}"
        log.error message, request: request
        request.missing data: {message}

  ###
  OUT:
    promise.then -> response
      response may or maynot be successful, but it is always returned via the promise-success path

    promise.catch -> always means an internal failure
  ###
  _applyAfterFilters: (response) ->
    Promise.try =>
      filters = @getAfterFilters response
      filterIndex = 0

      applyNextFilter = (previousResponse)->
        if filterIndex >= filters.length
          # done!
          previousResponse
        else
          filter = filters[filterIndex++]
          p = if previousResponse.notSuccessful && !filter.filterFailures
            Promise.resolve previousResponse
          else
            filter.processAfter previousResponse
          p.then (nextResponse) -> applyNextFilter nextResponse

      applyNextFilter response

  _normalizeRequest: (request) ->
    if isPlainObject request
      new Request merge request, pipeline: @
    else
      request

  _processRequest: (request) ->
    @_applyBeforeFilters @_normalizeRequest request
    .then (requestOrResponse)  => @_applyHandler requestOrResponse
    .then (response)           => @_applyAfterFilters response

  ###
  IN:
    type: request type string
    options:
      # options are passed to new Request
      # options are passed to response.toResponse

  OUT: response.toPromise options
    (SEE Response#toPromise for valid options)

    With no options, this means:
    promise.then (response.data) ->
      # status == success

    promise.catch (errorWithInfo) ->
      {response} = errorWithInfo.info
      # status != success
  ###
  noOptions = {}
  _processClientRequest: (type, options = noOptions) ->
    options = key: options if isString options
    {returnResponseObject} = options

    @createRequest type, options
    .then (request)  => @_processRequest request
    .then (response) => @_processResponseSession response
    .then (response) => response.toPromise options

  _processResponseSession: (response) ->
    {session} = response
    @session.data = session if session
    response

  @_defineClientRequestMethod: (requestType) ->
    @extendClientApiMethodList requestType unless requestType in @getClientApiMethodList()
    @::[requestType] ||= (options) -> @_processClientRequest requestType, options

  @_defineClientHandlerMethods: ->
    for name, handler of @getHandlers()
      @_defineClientRequestMethod name

  @_initFields: ->
    @extendFields filter.fields for filter in @getFilters()
