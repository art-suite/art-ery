Foundation = require 'art-foundation'
Response = require './Response'
Request = require './Request'
Filter = require './Filter'
Session = require './Session'
Config = require './Config'

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

  @extendableProperty
    queries: {}
    filters: []
    handlers: {}
    clientApiMethodList: []
    fields: {}

  @getAliases: -> @_aliases || {}

  ###
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

  preprocessFilter = (filter) ->
    if isPlainArray filter
      instantiateFilter f for f in filter when f
    else
      instantiateFilter filter

  @query:     (queries)  -> @extendQueries  queries
  @handler:   (handlers) -> @extendHandlers handlers
  @filter:    (filter)   -> @extendFilters preprocessFilter filter

  @getter
    aliases: -> Object.keys @class.getAliases()
    inspectedObjects: -> inspectedObjectLiteral @name
    isRemoteClient: -> @remoteServer

    remoteServer: ->
      return unless @remoteServerInfo
      {domain, port, apiRoot, protocol} = @remoteServerInfo
      protocol ||= "http"
      ret = "#{protocol}://#{domain}"
      ret += ":#{port}" if port
      ret

    apiRoot: ->
      if r = @remoteServerInfo?.apiRoot
        "/#{r}"
      else
        ""

    restPath: -> @_restPath ||= "#{@apiRoot}/#{@name}"
    restPathRegex: -> @_restPathRegex ||= ///
      ^
      #{escapeRegExp @restPath}
      (?:-([a-z0-9_]+))?          # optional request-type (if missing, it is derived from the HTTP method)
      (?:\/([-_.a-z0-9]+))?       # optional key
      ///i

  ######################
  # constructor
  ######################
  constructor: (@_options = {}) ->
    super

  @getter "options",
    tableName: -> Config.getPrefixedTableName @name
    normalizedFields: ->
      nf = {}
      for k, v of @fields
        nf[k] = normalizeFieldProps v
      nf

  @getter
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

    beforeFilters: -> @_beforeFilters ||= @filters.slice().reverse()
    afterFilters: -> @filters

  getBeforeFiltersFor: (type) -> filter for filter in @beforeFilters when filter.getBeforeFilter type
  getAfterFiltersFor:  (type) -> filter for filter in @afterFilters  when filter.getAfterFilter type

  ###
  OVERRIDE
  OUT: queryModelName:
    query: (queryKey, pipeline) -> array of plain objects
  ###
  getAutoDefinedQueries: -> {}

  getPipelineReport: ->
    tableName: @tableName
    fields: newObjectFromEach @fields, (fieldProps) ->
      newObjectFromEach Object.keys(fieldProps).sort(), (out, index, k) ->
        v = fieldProps[k]
        unless k == "preprocess" || k == "validate" || k == "fieldType"
        #   out[k + if peek(k) == "e" then "d" else "ed"] = true
        # else
          out[k] = v

    requests:
      newObjectFromEach @requestTypes, (type) =>
        inspectedObjectLiteral compactFlatten([
          filter.getName() for filter in @getBeforeFiltersFor type
          "[#{type}-handler]" if @handlers[type]
          filter.getName() for filter in @getAfterFiltersFor type
        ]).join ' > '

  getApiReport: (options = {}) ->
    {server} = options
    newObjectFromEach @requestTypes, (type) =>
      {method, url} = Request.getRestClientParamsForArtEryRequest
        server: @remoteServer || server
        type: type
        restPath: @restPath
      "#{method.toLocaleUpperCase()}": url

  ######################
  # Add Filters
  ######################


  ###
  handlers are merely the "pearl" filter - the action that happens
   - after all before-filters and
   - before all after-filters

  IN: map from request-types to request handlers:
    (request) -> request OR response OR result which will be converted to a response
  ###
  @handlers: @extendHandlers

  ###################
  # PRIVATE
  ###################
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

    applyNextFilter = (partiallyBeforeFilteredRequest) ->
      if partiallyBeforeFilteredRequest.isResponse || filterIndex >= filters.length
        Promise.resolve partiallyBeforeFilteredRequest
      else
        filters[filterIndex++].processBefore partiallyBeforeFilteredRequest
        .then (result) -> applyNextFilter result

    applyNextFilter request

  _applyHandler: (request) ->
    return request if request.isResponse
    if @isRemoteClient && !request.originatedOnClient
      request.sendRemoteRequest @remoteServer
    else if handler = @handlers[request.type]
      request.addFilterLog "#{request.type}-handler"
      request.next handler.call @, request
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
    # log _processRequest: request
    request = new Request merge request, pipeline: @ if isPlainObject request
    @_applyBeforeFilters request
    .then (request)  => @_applyHandler request
    .then (response) => @_applyAfterFilters response
    .catch (error)   =>
      log.error
        Pipeline_processRequest:
          error: error
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
