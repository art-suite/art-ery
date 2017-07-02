throw new Error "Neptune.Art.Flux not loaded. Please pre-require Flux or Flux/web_worker." unless Neptune.Art.Flux
{FluxModel, models} = Neptune.Art.Flux

ArtEry = require 'art-ery'
ArtEryQueryFluxModel = require './ArtEryQueryFluxModel'

{
  each
  log
  CommunicationStatus
  select
  isString
  isFunction
  fastBind
  decapitalize
  merge
  Promise
  eq
  upperCamelCase
  arrayWith
  arrayWithElementReplaced
  formattedInspect
  defineModule
  createWithPostCreate
  inspect
  compactFlatten
  object
  isPlainObject
} = Neptune.Art.Foundation

{missing, success, pending} = CommunicationStatus


defineModule module, class ArtEryFluxModel extends ArtEry.KeyFieldsMixin FluxModel
  @abstractClass()


  ###
  ALIASES
    both pipelines and models will have the same set of aliases
    This skips the aliases in pipelines and calls createModel only once
    which will in turn create all the model aliases.
    It's important that all the model aliases are the same model-instance object.

  OUT: singleton for new AnonymousArtErtFluxModel class
  ###
  @createModel: (pipeline) ->
    {aliases} = pipeline
    name = pipeline.getName()
    return if models[name]
    # log "create FluxModel for pipeline: #{name}"
    hotReloadKey = "ArtEryFluxModel:#{name}"
    createWithPostCreate class AnonymousArtErtFluxModel extends @applyMixins pipeline, ArtEryFluxModel
      @_name: ucName = upperCamelCase name
      @keyFields pipeline.keyFields if pipeline.keyFields
      @pipeline pipeline
      @aliases aliases if aliases
      @getHotReloadKey: -> hotReloadKey

  @applyMixins: (pipeline, BaseClass) ->

    # apply mixins
    for customMixin in compactFlatten pipeline.getFluxModelMixins()
      BaseClass = customMixin BaseClass

    BaseClass

  @defineModelsForAllPipelines: =>
    for name, pipeline of ArtEry.pipelines when name == pipeline.getName()
      @createModel pipeline

  @pipeline: (@_pipeline) -> @_pipeline
  @getter "pipeline"

  ########################
  # Constructor
  ########################
  constructor: ->
    super
    @_updateSerializers = {}
    @_pipeline = @class._pipeline
    @_defineQueryModels()
    @_bindPipelineMethods()

  ########################
  # Queries
  ########################
  _defineQueryModels: ->
    @_queryModels = object @_pipeline.queries, (pipelineQuery) =>
      @_createQueryModel pipelineQuery

  _createQueryModel: ({options, queryName}) ->

    prototypeProperties = merge options, {
      @_pipeline
      _recordsModel: @
      query: (key) -> @_pipeline[queryName] key: key, props: include: "auto"
    }

    new class ArtEryQueryFluxModelChild extends @class.applyMixins @_pipeline, ArtEryQueryFluxModel
      @_name: upperCamelCase queryName

      @::[k] = v for k, v of prototypeProperties

  ########################
  # FluxModel Overrides
  ########################
  loadData: (key) ->
    @_pipeline.get returnNullIfMissing: true, key: key, props: include: "auto"

  ################################################
  # DataUpdatesFilter callbacks
  ################################################
  ###
  TODO: What if the field that changes effects @dataToKeyString???
    Basically, then TWO query results for one query-model need updated - the old version gets a "delete"
    The new version gets the normal update.

    We -could- do a fluxStore.get and see if we have a local copy of the single record before we
    replace it. However, we often won't. However again, we may not NEED this often.

    Basically, the question becomes how do we get the old data - if we need it and it actually matters.

    The ArtEry Pipeline knows its queries - and in theory could know the fields which effect queries.
    DataUpdatesFilter could detect all this before: update. If it detects it, it could GET the old
    record, and then set responseProps.oldData: oldData. Then, DataUpdatesFilter could pass
    oldData into dataUpdated. DONE.

    OK - I added the oldData input, and I attempt to get it from the fluxStore if it isn't set.
    I think the code is right for handling the case where we need to update to queries.

    TODO: We need to do the Server-Side "fetch the old data if queries-keys will change" outline above.
    TODO: DataUpdatesFilter needs change the protocol to return oldData, too, if needed - there may be more than one oldData per request.
    TODO: DataUpdatesFilter needs to pass in: response.props.oldData[key]
  ###
  dataUpdated: (key, data) ->
    oldData = @fluxStoreGet(key)?.data
    data = merge oldData, data

    @updateFluxStore key, (oldFluxRecord) -> merge oldFluxRecord, {data}

    each @_queryModels, (queryModel) =>
      oldQueryKey = oldData && queryModel.dataToKeyString oldData
      queryKey    = queryModel.dataToKeyString data

      queryModel.dataDeleted oldQueryKey, oldData if oldQueryKey && oldQueryKey != queryKey
      queryModel.dataUpdated queryKey, data       if queryKey

  dataDeleted: (key, dataOrKey) ->
    @updateFluxStore key, status: missing

    dataOrKey && each @_queryModels, (queryModel) =>
      queryKey = queryModel.toKeyString dataOrKey
      queryKey && queryModel.dataDeleted queryKey, dataOrKey

  ##########################
  # PRIVATE
  ##########################

  ###
  Bind all concrete methods defined on @_pipeline
  and set them on the model prototype
  as long as there isn't already a model-prototype method with that name.

  Specifically: create & update are already defined above
    since they need to do extra work to ensure the FluxStore is
    updated properly.
  ###
  _bindPipelineMethods: ->
    abstractPrototype = @_pipeline.class.getAbstractPrototype()
    for k, v of @_pipeline when !@[k] && !abstractPrototype[k] && isFunction v
      @[k] = fastBind v, @_pipeline

