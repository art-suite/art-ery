Foundation = require 'art-foundation'
Response = require './Response'
Request = require './Request'
Filter = require './Filter'
Session = require './Session'
{config} = require './Config'

PipelineRegistry = require './PipelineRegistry'

{
  newObjectFromEach
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
} = Foundation
{normalizeFieldProps} = Validator

{success, missing, failure} = CommunicationStatus

defineModule module, class Pipeline extends require './ArtEryBaseObject'

  @register: ->
    @singletonClass()
    PipelineRegistry.register @

  # copy-paste this line to any sub-class that shouldn't auto-register
  @abstractClass()

  @postCreateConcreteClass: ({hotReloaded}) ->
    @register() unless hotReloaded
    @_defineQueryHandlers()
    @_initClientApiRequest()
    @_initFields()
    super

  @instantiateFilter: instantiateFilter = (filter) ->
    if isClass filter                 then new filter
    else if isFunction filter         then filter @
    else if filter instanceof Filter  then filter
    else if isPlainObject filter      then new Filter filter
    else throw "invalid filter: #{inspect filter} #{filter instanceof Filter}"

  @getAliases: -> @_aliases || {}

  ###########################
  # Declarative API
  ###########################
  @extendableProperty
    queries: {}
    filters: []
    handlers: {}
    clientApiMethodList: []
    fields: {}

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
  @query:         @extendQueries

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
    @_aliases = newObjectFromEach arguments, (map, k, v) ->
      map[lowerCamelCase v] = true
    @

  ######################
  # constructor
  ######################
  constructor: (@_options = {}) ->
    super

  getPrefixedTableName: (tableName) => "#{@tableNamePrefix}#{tableName}"

  @getter "options",
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
      if @remoteServer
        config.location
      else "both"

    restPath: -> @_restPath ||= "/#{config.apiRoot}/#{@name}"
    restPathRegex: -> @_restPathRegex ||= ///
      ^
      #{escapeRegExp @restPath}
      (?:-([a-z0-9_]+))?          # optional request-type (if missing, it is derived from the HTTP method)
      (?:\/([-_.a-z0-9]+))?       # optional key
      ///i

    beforeFilters: -> @_beforeFilters ||= @filters.slice().reverse()
    afterFilters: -> @filters

  getBeforeFiltersFor: (type, location = @location) -> filter for filter in @beforeFilters when filter.getBeforeFilter type, location
  getAfterFiltersFor:  (type, location = @location) -> filter for filter in @afterFilters  when filter.getAfterFilter  type, location

  ###
  OVERRIDE
  OUT: queryModelName:
    query: (queryKey, pipeline) -> array of plain objects
  ###
  getAutoDefinedQueries: -> {}

  ###############################
  # Development Reports
  ###############################
  getRequestProcessingReport: (processingLocation = config.location) ->
    newObjectFromEach @requestTypes, (type) =>
      inspectedObjectLiteral compactFlatten([
        filter.getName() for filter in @getBeforeFiltersFor type, processingLocation
        "[remote request]"
        filter.getName() for filter in @getAfterFiltersFor type, processingLocation
      ]).join ' > '

  getPipelineReport: ->
    tableName: @tableName
    fields: newObjectFromEach @fields, (fieldProps) ->
      newObjectFromEach Object.keys(fieldProps).sort(), (out, index, k) ->
        v = fieldProps[k]
        unless k == "preprocess" || k == "validate" || k == "fieldType"
        #   out[k + if peek(k) == "e" then "d" else "ed"] = true
        # else
          out[k] = v

    clientSideRequestProcessing: @getRequestProcessingReport "client"
    serverSideRequestProcessing: @getRequestProcessingReport "server"
    serverlessDevelopmentRequestProcessing: @getRequestProcessingReport "both"

  getApiReport: (options = {}) ->
    {server} = options
    newObjectFromEach @requestTypes, (type) =>
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

  @_defineQueryHandlers: ->
    for k, v of @getQueries()
      @extendHandlers k, if isFunction v then v else
        v = v.query
        unless isFunction v
          throw new Error "query delaration must be a function or have a 'query' property that is a function"
        v

  _applyBeforeFilters: (request) ->
    filters = @getBeforeFiltersFor request.type
    filterIndex = 0

    applyNextFilter = (partiallyBeforeFilteredRequest) =>
      if partiallyBeforeFilteredRequest.isResponse || filterIndex >= filters.length
        Promise.resolve partiallyBeforeFilteredRequest
      else
        (filter = filters[filterIndex++]).processBefore partiallyBeforeFilteredRequest
        .then (result) =>
          result.handled "beforeFilter: #{filter}" if result.isResponse
          applyNextFilter result

    applyNextFilter request

  _applyHandler: (request) ->
    return request if request.isResponse
    if config.location == "client" && @remoteServer
      request.sendRemoteRequest @remoteServer

    else if handler = @handlers[request.type]
      request.next handler.call @, request
      .then (response) =>
        response.handled "handler"

    else
      message = "no Handler for request type: #{request.type}"
      log.error message, request: request
      request.missing data: {message}

  _applyAfterFilters: (response) ->
    filters = @getAfterFiltersFor response.type
    filterIndex = 0

    applyNextFilter = (partiallyAfterFilteredReponse)->
      if partiallyAfterFilteredReponse.notSuccessful || filterIndex >= filters.length
        Promise.resolve partiallyAfterFilteredReponse
      else
        filters[filterIndex++].processAfter partiallyAfterFilteredReponse
        .then (result) -> applyNextFilter result

    applyNextFilter response

  _processRequest: (request) ->
    request = new Request merge request, pipeline: @ if isPlainObject request
    @_applyBeforeFilters request
    .then (request)  => @_applyHandler request
    .then (response) => @_applyAfterFilters response
    .catch (error)   =>
      # log.error
      #   Pipeline_processRequest:
      #     error: error
      request.next error

  # client actions just return the data and update the local session object if successful
  # otherwise, they "reject" the whole response object.
  ###
  options
    all the Request options are valid here
    returnResponseObject: true [default: false]
      if true, the response object is returned, otherwise, just the data field is returned.
  ###
  noOptions = {}
  _processClientRequest: (type, options = noOptions) ->
    {returnResponseObject} = options
    options = key: options if isString options

    @_processRequest new Request merge options,
      type:     type
      pipeline: @
      session:          @session.data
      sessionSignature: @session.signature

    .then (response) =>
      {status, data, session, sessionSignature} = response
      if status == success
        if session
          @session.data = session
          @session.signature = sessionSignature
        if returnResponseObject then response else data
      else
        throw response

  @_clientApiRequest: (requestType) ->
    @extendClientApiMethodList requestType unless requestType in @getClientApiMethodList()
    @::[requestType] ||= (options) -> @_processClientRequest requestType, options

  @_initClientApiRequest: ->
    for name, handler of @getHandlers()
      @_clientApiRequest name

  @_initFields: ->
    @extendFields filter.fields for filter in @getFilters()
