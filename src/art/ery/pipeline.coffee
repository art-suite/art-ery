Foundation = require 'art-foundation'
Response = require './Response'
Request = require './Request'
Filter = require './Filter'
Session = require './Session'

PipelineRegistry = require './PipelineRegistry'

{
  BaseObject, reverseForEach, Promise, log, isPlainObject, inspect, isString, isClass, isFunction, inspect
  CommunicationStatus
  merge
  isPlainArray
  decapitalize
  defineModule
  Validator
} = Foundation

{success, missing, failure} = CommunicationStatus
{toResponse} = Response

defineModule module, class Pipeline extends require './ArtEryBaseObject'
  @_namedPipelines = {}
  @addNamedPipeline: (name, pipeline) =>
    throw new Error "named pipeline already exists: #{name}" if @_namedPipelines[name]
    @_namedPipelines[name] = pipeline

  # for testing
  @_resetNamedPipelines: -> @_namedPipelines = {}

  @register: ->
    @singletonClass()
    PipelineRegistry.register @

  @postCreate: ({hotReloaded}) ->
    @register() unless hotReloaded || @ == Pipeline
    super

  @getNamedPipelines: => @_namedPipelines
  @getNamedPipeline: (name) =>
    throw new Error "named pipeline does not exist: #{name}" unless pl = @_namedPipelines[name]
    pl

  @instantiateFilter: instantiateFilter = (filter) ->
    if isClass filter                 then new filter
    else if isFunction filter         then filter @
    else if filter instanceof Filter  then filter
    else if isPlainObject filter
      new class AnonymousFilter extends Filter
        @before filter.before
        @after filter.after
    else throw "invalid filter: #{inspect filter} #{filter instanceof Filter}"

  @getFilters: -> @getPrototypePropertyExtendedByInheritance "classFilters", []
  @getClientApiMethodList: -> @getPrototypePropertyExtendedByInheritance "classClientApiMethodList", []

  ######################
  # constructor
  ######################
  constructor: (@_options = {}) ->
    super
    @_fields = {}
    @_filters = []

    @filter filter for filter in @class.getFilters()

  @getter "filters fields options",
    pipelines: -> Pipeline.getNamedPipelines()
    clientApiMethodList: -> @class.getClientApiMethodList()
    tableName: -> @name
    normalizedFields: ->
      nf = {}
      {normalizeFieldType} = Validator
      for k, v of @fields
        nf[k] = normalizeFieldType v
      nf

  @getter
    name:    -> @_name    ||= @_options.name    || decapitalize @class.getName()
    queries: -> @_queries ||= @_options.queries || {}
    actions: -> @_actions ||= @_options.actions || {}
    session: -> @_session ||= @_options.session || Session.singleton

  ###
  OVERRIDE
  OUT: queryModelName:
    query: (queryKey, pipeline) -> array of plain objects
  ###
  getAutoDefinedQueries: -> {}

  ######################
  # Add Filters
  ######################

  # IN: instanceof Filter or class extending Filter or function returning instance of Filter
  # OUT: @
  @filter: (filter) -> @getFilters().push filter; @
  filter: (filter) ->
    if isPlainArray filter
      @filter f for f in filter
      @
    else
      @getFilters().push filter = instantiateFilter filter
      @_fields = merge @_fields, filter.fields
      @

  ###
  handlers are merely the "pearl-filter" - the action that happens
   - after all before-filters and
   - before all after-filters

  IN: map from request-types to request handlers:
    (request) -> request OR response OR result which will be converted to a response
  ###
  @handlers: (map) ->
    class HandlerFilter extends Filter
    @filter HandlerFilter
    for name, handler of map
      do (name, handler) =>
        @_clientApiRequest name
        HandlerFilter.before name, (request) ->
          handler.call request.pipeline, request

  ###################
  # PRIVATE
  ###################
  _performRequest: (request) ->
    {type} = request
    {filters} = @
    handlerIndex = filters.length - 1

    # IN: Request instance
    # OUT:
    #   promise.then (successful Response instance) ->
    #   .catch (unsuccessful Response instance) ->
    processNext = (request) ->
      if handlerIndex < 0
        Promise.resolve new Response request: request, status: failure, error: message: "no filter generated a Response"
      else
        filters[handlerIndex--].process request, processNext

    processNext request

  # client actions just return the data and update the local session object if successful
  # otherwise, they "reject" the whole response object.
  _performClientRequest: (type, keyOrData, data) ->
    if !data && keyOrData && !isString keyOrData
      key = null
      data = keyOrData
    else
      key = keyOrData

    @_performRequest new Request
      type:     type
      key:      key
      pipeline: @
      data:     data
      session:  @session.data

    .then (response) =>
      {status, data, session} = response
      if status == success
        @session.data = session if session
        data
      else
        throw response

  @_clientApiRequest: (requestType) ->
    @getClientApiMethodList().push requestType unless requestType in @getClientApiMethodList()
    @::[requestType] ||= (keyOrData, data) -> @_performClientRequest requestType, keyOrData, data

  # @_clientApiRequest "get"
  # @_clientApiRequest "update"
  # @_clientApiRequest "create"
  # @_clientApiRequest "delete"
