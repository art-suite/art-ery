Foundation = require 'art-foundation'
{Flux} = Neptune.Art
throw new Error "Neptune.Art.Flux not loaded. Please pre-require Flux or Flux/web_worker." unless Flux
ArtEry = require 'art-ery'
ArtEryQueryFluxModel = require './ArtEryQueryFluxModel'

{
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
} = Foundation

{missing, failure, success, pending} = CommunicationStatus

{FluxModel, models} = Flux

defineModule module, class ArtEryFluxModel extends FluxModel

  createModel = (name, pipeline, aliases) ->
    klass = createWithPostCreate class AnonymouseArtErtFluxModel extends ArtEryFluxModel
      @_name: upperCamelCase name
      @pipeline pipeline
      @aliases aliases if aliases
    klass.singleton

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

  @postCreate: ->
    if @_pipeline
      super
    else
      @

  constructor: ->
    super
    @_updateSerializers = {}
    @_pipeline = @class._pipeline
    @_queryModels = {}
    @queries @_pipeline.queries
    @_bindPipelineMethods()

  _bindPipelineMethods: ->
    abstractPrototype = @_pipeline.class.firstAbstractAncestor.prototype
    for k, v of @_pipeline when !@[k] && !abstractPrototype[k] && isFunction v
      @[k] = fastBind v, @


  keyFromData: (data) ->
    ret = @_pipeline.keyFromData?(data) || data.id
    throw new Error "keyFromData: failed to generate a key from: @_pipeline.keyFromData?(data) || data.id)" unless ret
    ret
  keysEqual: (a, b) -> eq @keyFromData(a), @keyFromData(b)

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

      query: (key) -> @_pipeline[modelName] key: key

  ###
  IN: key: string
  OUT:
    promise.then (data) ->
    promise.catch (response with .status and .error) ->
  ###
  load: (key) ->
    throw new Error "invalid key: #{inspect key}" unless isString key
    @_getUpdateSerializer key
    .updateFluxStore =>
      @_pipeline.get key: key
    false

  create: (data) ->
    @_pipeline.create data: data
    .then (data) =>
      @updateFluxStore @keyFromData(data),
        status: success
        data: data
      data

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
      updateSerializer.then => @fluxStoreGet(key)?.data || {}
      updateSerializer.updateFluxStore = (updateFunction) =>
        updateSerializer.then (data) =>
          Promise.resolve updateFunction data
          .catch -> data # on error, roll back flux-Store to the last known-good data
          .then (data) =>
            @updateFluxStore key, status: success, data: data
            data
        updateSerializer

    updateSerializer.allDonePromise().then (accumulatedSuccessfulUpdatesToData) =>
      delete @_updateSerializers[key]
    updateSerializer

  _updateQueries: (updatedRecord) ->
    queryModel.localUpdate updatedRecord for modelName, queryModel of @_queryModels
    null

  fluxStoreEntryUpdated: ({key, fluxRecord}) ->
    @_updateQueries fluxRecord.data

  _optimisticallyUpdateFluxStore: (key, fieldsToUpdate) ->
    # apply local update immediately
    # This optimistically updates the local copy assuming all updates will succeed
    @updateFluxStore key,
      (oldFluxRecord) => merge oldFluxRecord, data: merge oldFluxRecord?.data, fieldsToUpdate

  update: (key, data) ->
    throw new Error "invalid key: #{inspect key}" unless isString key

    @_optimisticallyUpdateFluxStore key, data

    ###
    creating a Promise here because we have two promise paths
    path 1: the caller of this update wants to know when this specific update
      succeeds or fails.
    path 2: the updateSerializer must continue whether or not
    ###
    new Promise (resolve, reject) =>
      @_getUpdateSerializer key
      .updateFluxStore (accumulatedSuccessfulUpdatesToData) =>
        ###
        NOTE if this update fails:

          The FluxStore record gets rolled back to the version just before this
          update was called. All pending updates after this one will be 'lost'
          in the fluxStore UNTIL, and if, those pending updates succeed. As they
          succeed, the fluxStore will be updated.

          So, technically, it isn't the MOST accurate representation if a
          previous update failed, but it will be resolved to the most accurate
          representation once all updates have completed or failed.
        ###
        ret = @_pipeline.update key: key, data: data
        .then -> merge accumulatedSuccessfulUpdatesToData, data
        ret.then resolve, reject
        ret

        ###
        NOTE: this could be done more cleanly with tapThen (see Art.Foundation.Promise)

        @_pipeline.update key, data
        .then -> merge accumulatedSuccessfulUpdatesToData, data
        .tapThen resolve, reject

        ###
