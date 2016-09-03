Foundation = require 'art-foundation'
Flux = require 'art-flux'
ArtEry = require 'art-ery'
ArtEryQueryFluxModel = require './ArtEryQueryFluxModel'

{
  log
  CommunicationStatus
  select
  isString
  isFunction
  decapitalize
  merge
  Promise
  eq
  upperCamelCase
  arrayWith
  arrayWithElementReplaced
  formattedInspect
} = Foundation

{missing, failure, success, pending} = CommunicationStatus

{FluxModel} = Flux

module.exports = class ArtEryFluxModel extends FluxModel

  @pipeline: (@_pipeline) ->
    @register()
    @_pipeline.tableName = @getName()
    Neptune.Art.Ery.Pipeline.addNamedPipeline @getName(), @_pipeline
    @_pipeline

  @getter "pipeline"

  constructor: ->
    super
    @_updateSerializers = {}
    @_pipeline = @class._pipeline
    @queries @_pipeline.queries
    @actions @_pipeline.actions

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
  queries: (map) ->
    @_queryModels = for modelName, options of map
      if isFunction options
        options = query: options
      {_pipeline} = @
      recordsModel = @
      throw new Error "query required" unless isFunction options.query

      new class ArtEryQueryFluxModelChild extends ArtEryQueryFluxModel
        @_name: upperCamelCase modelName

        @::[k] = v for k, v of options
        _pipeline: _pipeline
        _recordsModel: recordsModel

  ###
  TODO:
  actions need to go through an ArtEry pipeline.
  actions should be invoked with that ArtEry pipeline as @
  ###
  actions: (map) ->
    for actionName, action of map
      @[actionName] = action

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
      @_pipeline.get key
    false

  create: (data) ->
    @_pipeline.create data
    .then (data) =>
      @updateFluxStore @keyFromData(data),
        status: success
        data: data

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
    queryModel.localUpdate updatedRecord for queryModel in @_queryModels
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
        ret = @_pipeline.update key, data
        .then -> merge accumulatedSuccessfulUpdatesToData, data
        ret.then resolve, reject
        ret

        ###
        NOTE: this could be done more cleanly with tapThen (see Art.Foundation.Promise)

        @_pipeline.update key, data
        .then -> merge accumulatedSuccessfulUpdatesToData, data
        .tapThen resolve, reject

        ###
