Foundation = require 'art-foundation'
{Flux} = Neptune.Art
ArtEry = require 'art-ery'

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
  propsEq
  defineModule
  arrayWithout
} = Foundation

{missing, failure, success, pending} = CommunicationStatus

{FluxModel} = Flux

defineModule module, class ArtEryQueryFluxModel extends FluxModel
  @abstractClass()
  ###
  This class is designed to be extended with overrides:

  ###
  constructor: ->
    super null
    @register()

  loadData: (key) ->
    Promise.resolve @query key, @pipeline
    .then (data) => @localSort data

  @setter "recordsModel pipeline"
  @getter "recordsModel pipeline"

  ###
  OVERRIDE
  IN: will be the key (returned from fromFluxKey)
  OUT: array of singleModel records
    OR promise.then (arrayOfRecords) ->
  TODO:
    In the future we may wish to return other things beyond the array of records.
    Example:
      DynamoDb returns data for "getting the next page of records" in addition to the records.
      DynamoDb also returns other interesting stats about the query.

    If an array is returned, it will always be records. However, if an object is
    returned, then one of the fields will be records - and will go through the return
    pipeline, but the rest will be left untouched and placed in the FluxRecord's data field.
    Or should they be put in an auxiliary field???
  ###
  query: (key) -> []

  ###
  OVERRIDE
  IN: single record
  OUT: string key for the query results that should contain this record
  ###
  queryKeyFromRecord: (record) -> ""

  ###
  OVERRIDE
  override for to sort records when updating local query data in response to local record changes
  ###
  localSort: (queryData) -> queryData

  ###
  OVERRIDE
  override for custom merge
  This implementation is a streight-up merge using @recordsModel.dataHasEqualKeys

  IN:
    previousQueryData: array of records or null
    updatedRecordData: single record or null
  OUT: return null if nothing changed, else return a new array
  ###
  localMerge: (previousQueryData, updatedRecordData, wasDeleted) ->
    return null unless updatedRecordData

    unless previousQueryData?.length > 0
      return if wasDeleted then [] else [updatedRecordData]

    updatedRecordDataKey = @recordsModel.toKeyString updatedRecordData
    for currentRecordData, i in previousQueryData when updatedRecordDataKey == @recordsModel.toKeyString currentRecordData
      return if wasDeleted
        arrayWithout previousQueryData, i
      else if propsEq currentRecordData, updatedRecordData
        null
      else
        arrayWithElementReplaced previousQueryData, updatedRecordData, i

    # updatedRecordData wasn't in previousQueryData
    if wasDeleted
      null
    else
      arrayWith previousQueryData, updatedRecordData

  ###
  ArtEryFluxModel calls localUpdate on all its queries whenever
  a fluxStore entry is created or updated for the ArtEryFluxModel.

  OVERRIDABLE
  Can override for custom behavior!

  This implementation assumes there is only one possible result-set for a given query
  any particular record will belong to, and it assumes the queryKey
  can be computed via @queryKeyFromRecord.

  NOTE: @queryKeyFromRecord must be implemented!
  ###
  localUpdate: (updatedRecordData, wasDeleted = false) ->
    if (results = @getQueryResultsFromFluxStoreGivenExampleRecord updatedRecordData) && results.records
      {records, queryKey} = results

      if mergeResult = @localMerge records, updatedRecordData, wasDeleted
        @updateFluxStore queryKey, data: @localSort mergeResult

  getQueryResultsFromFluxStoreGivenExampleRecord: (exampleRecord) ->
    return unless exampleRecord
    queryKey = @queryKeyFromRecord? exampleRecord
    throw new Error "ArtEryQueryFluxModel #{@getName()} localUpdate: invalid queryKey generated #{formattedInspect {queryKey,exampleRecord}}" unless isString queryKey
    {queryKey, records: @fluxStoreGet(queryKey)?.data}
