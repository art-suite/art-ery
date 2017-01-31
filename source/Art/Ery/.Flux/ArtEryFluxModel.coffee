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
} = Neptune.Art.Foundation

{missing, failure, success, pending} = CommunicationStatus


defineModule module, class ArtEryFluxModel extends ArtEry.KeyFieldsMixin FluxModel
  @abstractClass()

  # OUT: singleton for new AnonymousArtErtFluxModel class
  createModel = (name, pipeline, aliases) ->
    createWithPostCreate class AnonymousArtErtFluxModel extends ArtEryFluxModel
      @_name: upperCamelCase name
      @pipeline pipeline
      @aliases aliases if aliases

  @defineModelsForAllPipelines: ->
    for name, pipeline of ArtEry.pipelines
      if aliases = pipeline.aliases
        # both pipelines and models will have the same set of aliases
        # This skips the aliases in pipelines and calls createModel only once
        # which will in turn create all the model aliases.
        # It's important that all the model aliases are the same model-instance object.
        name = pipeline.getName()
        createModel name, pipeline, aliases unless models[name]
      else
        createModel name, pipeline

  @pipeline: (@_pipeline) -> @_pipeline
  @getter "pipeline"

  ########################
  # Constructor
  ########################
  constructor: ->
    super
    @_updateSerializers = {}
    @_pipeline = @class._pipeline
    @_queryModels = {}
    @queries @_pipeline.queries
    @_bindPipelineMethods()

  ########################
  # Queries
  ########################
  ###
  TODO:
  queries need to go through an ArtEry pipeline.
  queries should be invoked with that ArtEry pipeline as @
  every record returned should get sent through the after-pipeline
  as-if it were a "get" request
  ###
  queries: (map, ignoreAlreadyDefinedWarning) ->
    for modelName, options of map
      @defineQuery modelName, options, ignoreAlreadyDefinedWarning

  defineQuery: (modelName, options, ignoreAlreadyDefinedWarning) ->
    if @_queryModels[modelName]
      console.warn "query already defined! #{@getName()}: #{modelName}" unless ignoreAlreadyDefinedWarning
      return

    {_pipeline} = @
    recordsModel = @
    options = query: options if isFunction options
    throw new Error "query required" unless isFunction options.query

    @_queryModels[modelName] = new class ArtEryQueryFluxModelChild extends ArtEryQueryFluxModel
      @_name: upperCamelCase modelName

      @::[k] = v for k, v of options
      _pipeline:      _pipeline
      _recordsModel:  recordsModel

      query: (key) -> @_pipeline[modelName] key: key, props: include: "auto"

  ########################
  # FluxModel Overrides
  ########################
  loadData: (key) ->
    @_pipeline.get key: key, props: include: "auto"

  ################################################
  # DataUpdatesFilter callbacks
  ################################################
  dataUpdated: (key, data) ->
    @updateFluxStore key, (oldFluxRecord) -> merge oldFluxRecord, data: oldFluxRecord.data, data
    @_updateQueries data

  dataDeleted: (key, data) ->
    @updateFluxStore key, -> status: missing

  ########################
  # Pipeline API Overrides
  ########################

  # Let's try w/o this. The new dataUpdated / dataDeleted system
  # will update things on reply. It's not quite as fast, but its
  # a lot easier to understand.
  # NOTE: the goal of this code was to update locally BEFORE sending a remote create/update
  # However, a lot of updates happen server-side in response to other calls than just 'create' and 'update'
  #
  # # NOTE - loadData won't be used if this is uncommented
  # load: (key) ->
  #   throw new Error "invalid key: #{inspect key}" unless isString key
  #   @_getUpdateSerializer key
  #   .updateFluxStore => @_pipeline.get key: key, props: include: "auto"
  #   false
  #
  # create: (data) ->
  #   @_pipeline.create data: data
  #   .then (data) =>
  #     @updateFluxStore @toKeyString(data),
  #       status: success
  #       data: data
  #     data

  # update: (key, updatedFields) ->
  #   throw new Error "invalid key: #{inspect key}" unless isString key

  #   ###
  #   creating a Promise here because we have two promise paths
  #   path 1: the caller of this update wants to know when this specific update
  #     succeeds or fails.
  #   path 2: the updateSerializer must continue whether or not
  #   ###
  #   new Promise (resolve, reject) =>
  #     @_getUpdateSerializer key
  #     # TODO: updateSerializer.updateFluxStore should optimisitically update the store
  #     # new signature might look like this:
  #     #   .updateFluxStore updatedFields, (accumulatedSuccessfulUpdatesToData) =>
  #     .updateFluxStore (accumulatedSuccessfulUpdatesToData) =>
  #       ###
  #       NOTE if this update fails:

  #         The FluxStore record gets rolled back to the version just before this
  #         update was called. All pending updates after this one will be 'lost'
  #         in the fluxStore UNTIL, and if, those pending updates succeed. As they
  #         succeed, the fluxStore will be updated.

  #         So, technically, it isn't the MOST accurate representation if a
  #         previous update failed, but it will be resolved to the most accurate
  #         representation once all updates have completed or failed.
  #       ###
  #       ret = @_pipeline.update key: key, data: updatedFields
  #       .then -> merge accumulatedSuccessfulUpdatesToData, updatedFields
  #       ret.then resolve, reject
  #       ret

  #       ###
  #       NOTE: this could be done more cleanly with tapThen (see Art.Foundation.Promise)

  #       @_pipeline.update key, updatedFields
  #       .then -> merge accumulatedSuccessfulUpdatesToData, updatedFields
  #       .tapThen resolve, reject

  #       ###

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

  ###
  Purpose:
    Allows multiple in-flight updates to update the flux-store with every success or failure
    to the current-best-known state of the remote record.
  Usage:
    updateSerializer = @_getUpdateSerializer key
    updateSerializer.updateFluxStore (accumulatedSuccessfulUpdatesToData) =>
      return updated data
    Effects:
      - after the returned, updated data is resolved, @updateFluxStore is called
      - calls to updateFluxStore are serialized:
        - each is executed and fluxStore is updated before the next

  Internal Notes:
    - auto vivifies
    When allDone:
    - removed from @_updateSerializers
  ###
  _getUpdateSerializer: (key) ->
    unless updateSerializer = @_updateSerializers[key]
      updateSerializer = new Promise.Serializer
       #prime the serializer with the current fluxRecord.data
      updateSerializer.then => @fluxStoreGet(key)?.data
      updateSerializer.updateFluxStore = (updateFunction) =>
        updateSerializer.then (data) =>
          Promise.then -> updateFunction data
          .then (data) ->
            status: success, data: data
          .catch (e) ->
            if data
              # on error, roll back flux-Store to the last known-good data
              status: success, data: data
            else
              status: e.info?.response?.status || failure
              data: e.info
          .then (fluxRecord) =>
            @updateFluxStore key, fluxRecord
            data
        updateSerializer

    updateSerializer.allDonePromise().then (accumulatedSuccessfulUpdatesToData) =>
      delete @_updateSerializers[key]
    updateSerializer

  _updateQueries: (updatedRecord, wasDeleted = false) ->
    each @_queryModels, (queryModel) ->
      queryModel.localUpdate updatedRecord, wasDeleted
    null
