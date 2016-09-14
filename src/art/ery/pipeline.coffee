Foundation = require 'art-foundation'
Response = require './Response'
Request = require './Request'
Filter = require './Filter'
Session = require './Session'

PipelineRegistry = require './PipelineRegistry'

{
  newMapFromEach
  compactFlatten
  BaseObject, reverseForEach, Promise, log, isPlainObject, inspect, isString, isClass, isFunction, inspect
  CommunicationStatus
  merge
  isPlainArray
  decapitalize
  defineModule
  Validator
  mergeInto
} = Foundation

{success, missing, failure} = CommunicationStatus

defineModule module, class Pipeline extends require './ArtEryBaseObject'

  @register: ->
    @singletonClass()
    PipelineRegistry.register @

  @postCreate: ({hotReloaded}) ->
    @register() unless hotReloaded || @ == Pipeline
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
    aliases: {}
    clientApiMethodList: []
    fields: {}

  ###
  INPUT: zero or more strings or arrays of strings
    - arbitrary nesting of arrays is OK
    - nulls are OK, they are ignored
  OUTPUT: null

  NOTE: @aliases can be called multiple times.

  example:
    class Post extends Pipeline
      @aliases "chapterPost"

  purpose:
    - declare alternative names to access this pipeline.
    - allows you to use the shortest form of FluxComponent subscriptions for each alias:
        @subscriptions "chapterPost"
      in addition to the pipeline's class name:
        @subscriptions "post"
  ###
  @aliases: ->
    aliases = @getAliases()
    aliases[alias] = true for alias in compactFlatten arguments
    @

  preprocessFilter = (filter) ->
    if isPlainArray filter
      instantiateFilter f for f in filter
    else
      instantiateFilter filter

  @query:     (queries)  -> @extendQueries  queries
  @handler:   (handlers) -> @extendHandlers handlers
  @filter:    (filter)   -> @extendFilters preprocessFilter filter

  @getter
    aliases: -> Object.keys @class.getAliases()

  ######################
  # constructor
  ######################
  constructor: (@_options = {}) ->
    super

  @getter "options",
    tableName: -> @name
    normalizedFields: ->
      nf = {}
      {normalizeFieldType} = Validator
      for k, v of @fields
        nf[k] = normalizeFieldType v
      nf

  @getter
    name:     -> @_name     ||= @_options.name    || decapitalize @class.getName()
    session:  -> @_session  ||= @_options.session || Session.singleton
    requestTypes: ->
      beforeFilters = {}
      beforeFilters[k] = true for k, filterFunction of @handlers
      for filter in @filters
        beforeFilters[k] = true for k, filterFunction of filter.beforeFilters
      Object.keys beforeFilters

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

  getPipelineReport: () ->
    newMapFromEach @requestTypes, (type) =>
      # return (f.getName() for f in @filters)
      compactFlatten([
        filter.getName() for filter in @getBeforeFiltersFor type
        "[#{type}-handler]" if @handlers[type]
        filter.getName() for filter in @getAfterFiltersFor type
      ]).join ' > '

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
    if handler = @handlers[request.type]
      request.addFilterLog "#{request.type}-handler"
      request.next handler.call @, request
    else
      message = "no Handler for request type: #{request.type}"
      log.error message, request: request
      request.with message, failure

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
    @_applyBeforeFilters request
    .then (request)  => @_applyHandler request
    .then (response) => @_applyAfterFilters response
    .catch (error)   => request.next error

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

    @_processRequest new Request merge options,
      type:     type
      pipeline: @
      session:  @session.data

    .then (response) =>
      {status, data, session} = response
      if status == success
        @session.data = session if session
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
