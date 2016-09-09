Foundation = require 'art-foundation'
Response = require './Response'
Request = require './Request'
Filter = require './Filter'
Session = require './Session'
HandlerFilter = require './HandlerFilter'

PipelineRegistry = require './PipelineRegistry'

{
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
{toResponse} = Response

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
    else if isPlainObject filter
      new class AnonymousFilter extends Filter
        @before filter.before
        @after filter.after
    else throw "invalid filter: #{inspect filter} #{filter instanceof Filter}"

  @extendableProperty
    queries: {}
    filters: [new HandlerFilter]
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

  ###
  OVERRIDE
  OUT: queryModelName:
    query: (queryKey, pipeline) -> array of plain objects
  ###
  getAutoDefinedQueries: -> {}

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

  _performRequest: (request) ->
    {type} = request
    {filters} = @
    filterIndex = filters.length - 1

    # IN: Request instance
    # OUT:
    #   promise.then (successful Response instance) ->
    #   .catch (unsuccessful Response instance) ->
    processNext = (request) ->
      Promise.then ->
        if filterIndex < 0
          new Response request: request, status: failure, error: message: "no Filter generated a Response for request type: #{request.type}"
        else
          filters[filterIndex--].process request, processNext

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
    @extendClientApiMethodList requestType unless requestType in @getClientApiMethodList()
    @::[requestType] ||= (keyOrData, data) -> @_performClientRequest requestType, keyOrData, data

  @_initClientApiRequest: ->
    for name, handler of @getHandlers()
      @_clientApiRequest name

  @_initFields: ->
    @extendFields filter.fields for filter in @getFilters()
